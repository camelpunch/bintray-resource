require 'minitest/autorun'
require 'minitest/focus'
require_relative '../../lib/bintray_resource/out'
require_relative '../../lib/bintray_resource/upload'
require_relative '../doubles/fake_http'

module BintrayResource
  class TestOut < Minitest::Test
    def setup
      @input = {
        "source" => {
          "api_key"         => "abcde123456",
          "api_version"     => "v1",
          "package"         => "rabbitmq_clusterer",
          "repo"            => "community-plugins",
          "subject"         => "rabbitmq",
          "username"        => "myuser",
        },
        "params" => {
          "file"            => "my-source/built-*.ez",
          "publish"         => true,
          "version_regexp"  => "my-source/(.*)/built-.*",
        },
      }
      @input_with_list = @input.merge(
        "params" => @input["params"].merge(
          "list_in_downloads" => true
        )
      )
    end

    def test_upload
      reader = ReaderStub.new(
        stub: {
          glob: "/sources/path/my-source/built-*.ez",
          regexp:  "my-source/(.*)/built-.*",
        },
        to_return: {
          "basename"  => "built-package12345.ez",
          "contents"  => "my-sweet-file-contents",
          "version"   => "3.6.5",
        }
      )
      http = FakeHttp.new
      resource = Out.new(reader: reader, upload: Upload.new(http: http))

      resource.call("/sources/path", @input)

      assert_equal(
        %w(https://myuser:abcde123456@bintray.com/api/v1/content/rabbitmq/community-plugins/rabbitmq_clusterer/3.6.5/built-package12345.ez?publish=1),
        http.put_uris
      )
      assert_equal(
        ["my-sweet-file-contents"],
        http.put_contents
      )
      assert_equal(
        [{"Content-Type" => "application/octet-stream"}],
        http.put_headers
      )
    end

    def test_uploads_and_makes_available_in_downloads_list
      reader = ReaderStub.new(
        stub: {
          glob: "/sources/path/my-source/built-*.ez",
          regexp:  "my-source/(.*)/built-.*",
        },
        to_return: {
          "basename"  => "built-package12345.ez",
          "contents"  => "my-sweet-file-contents",
          "version"   => "3.6.5",
        }
      )
      http = FakeHttp.new([200, 200], "")
      resource = Out.new(reader: reader, upload: Upload.new(http: http))

      resource.call("/sources/path", @input_with_list)

      assert_equal(
        %w(
        https://myuser:abcde123456@bintray.com/api/v1/content/rabbitmq/community-plugins/rabbitmq_clusterer/3.6.5/built-package12345.ez?publish=1
        https://myuser:abcde123456@bintray.com/api/v1/file_metadata/rabbitmq/community-plugins/built-package12345.ez
        ),
        http.put_uris
      )
      assert_equal(
        ["my-sweet-file-contents",
         JSON.generate("list_in_downloads" => true)],
        http.put_contents
      )
      assert_equal(
        [{"Content-Type" => "application/octet-stream"},
         {"Content-Type" => "application/json"}],
        http.put_headers
      )
    end

    def test_emits_version_passed_to_it
      reader = ReaderStub.new(to_return: { "version" => "1.2.3" })
      retval = Out.new(reader: reader, upload: Upload.new(http: FakeHttp.new)).
        call("/full/sources", @input)
      assert_equal({ "ref" => "1.2.3" }, retval["version"])
    end

    def test_result_of_put_is_placed_in_metadata
      resource = Out.new(
        reader: ReaderStub.new,
        upload: Upload.new(
          http: FakeHttp.new([200], '{"result":"success"}')
        )
      )
      retval = resource.call("/sources/path", @input)

      assert_equal(
        [
          { "name" => "response",
            "value" => '{"result":"success"}' },
        ],
        retval["metadata"]
      )
    end

    def test_ignores_already_exists_failure
      reader = ReaderStub.new(
        stub: {
          glob: "/sources/path/my-source/built-*.ez",
          regexp:  "my-source/(.*)/built-.*",
        },
        to_return: {
          "basename"  => "built-package12345.ez",
          "contents"  => "my-sweet-file-contents",
          "version"   => "3.6.5",
        }
      )
      http = FakeHttp.new([409, 200], "")
      resource = Out.new(reader: reader, upload: Upload.new(http: http))

      resource.call("/sources/path", @input_with_list)

      assert_equal(
        "https://myuser:abcde123456@bintray.com/api/v1/file_metadata/rabbitmq/community-plugins/built-package12345.ez",
        http.put_uris[1]
      )
      assert_equal(
        JSON.generate("list_in_downloads" => true),
        http.put_contents[1]
      )
    end

    def test_failure_in_upload_raises_exception
      resource = Out.new(
        reader: ReaderStub.new,
        upload: Upload.new(
          http: FakeHttp.new([400], '{"result":"failure"}'),
          retries: 1
        )
      )
      assert_raises(BintrayResource::Upload::FailureResponse) do
        resource.call("/sources/path", @input)
      end
    end

    def test_500_failure_in_downloads_list_raises_exception
      resource = Out.new(
        reader: ReaderStub.new,
        upload: Upload.new(
          http: FakeHttp.new([200, 500], '{"result":"failure"}'),
          retries: 1
        )
      )
      assert_raises(BintrayResource::Upload::FailureResponse) do
        resource.call("/sources/path", @input_with_list)
      end
    end

    class SleeperSpy
      attr_accessor :sleeps

      def initialize
        @sleeps = []
      end

      def sleep(seconds)
        @sleeps << seconds
      end
    end

    def test_400_failure_in_downloads_list_tries_again_with_backoff
      sleeper = SleeperSpy.new
      resource = Out.new(
        reader: ReaderStub.new,
        upload: Upload.new(
          http: FakeHttp.new([200, 400, 400, 400, 200], ''),
          sleeper: sleeper
        )
      )
      normal_response = {"version" => {"ref" => nil},
                         "metadata" => [{"name" => "response",
                                         "value" => ""}]}
      assert_equal(
        normal_response,
        resource.call("/sources/path", @input_with_list)
      )
      assert_equal([1, 2, 4], sleeper.sleeps)
    end

    def test_400_failure_has_retry_limit
      resource = Out.new(
        reader: ReaderStub.new,
        upload: Upload.new(
          http: FakeHttp.new([200, 400, 400, 400], ''),
          sleeper: SleeperSpy.new,
          retries: 3
        )
      )
      assert_raises(BintrayResource::Upload::FailureResponse) do
        resource.call("/sources/path", @input_with_list)
      end
    end

    class ReaderStub
      def initialize(stub: {}, to_return: {})
        @stubs = stub
        @read_return = to_return
      end

      def read(actual_glob, actual_regexp)
        if @stubs.empty? || actual_glob == @stubs[:glob] && actual_regexp == @stubs[:regexp]
          @read_return
        else
          {
            "basename" => "notstubbed",
            "contents" => "notstubbed",
            "version" => "notstubbed",
          }
        end
      end
    end
  end
end
