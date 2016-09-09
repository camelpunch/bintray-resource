require 'minitest/autorun'
require 'minitest/focus'
require_relative '../../../lib/bintray_resource/out'
require_relative '../../../lib/bintray_resource/upload'
require_relative '../../doubles/fake_http'
require_relative '../../doubles/upload_spy'

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
          "licenses"        => ["Mozilla-1.1"],
          "vcs_url"         => "https://github.com/rabbitmq/rabbitmq-clusterer",
        },
      }
      @input_with_list = @input.merge(
        "params" => @input["params"].merge(
          "list_in_downloads" => true
        )
      )
    end

    def test_create_and_upload
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
      upload = UploadSpy.new([201, 200], "")
      resource = Out.new(reader: reader, upload: upload)

      resource.call("/sources/path", @input)

      assert_equal(
        %w(
          https://myuser:abcde123456@bintray.com/api/v1/packages/rabbitmq/community-plugins
          https://myuser:abcde123456@bintray.com/api/v1/content/rabbitmq/community-plugins/rabbitmq_clusterer/3.6.5/built-package12345.ez?publish=1
        ),
        upload.uris
      )
      assert_equal(
        %i(
          post
          put
        ),
        upload.http_methods
      )
      assert_equal(
        [
          JSON.generate("name" => "rabbitmq_clusterer",
                        "licenses" => ["Mozilla-1.1"],
                        "vcs_url" => "https://github.com/rabbitmq/rabbitmq-clusterer"),
          "my-sweet-file-contents"
        ],
        upload.contents
      )
      assert_equal(
        [
          {"Content-Type" => "application/json"},
          {"Content-Type" => "application/octet-stream"},
        ],
        upload.headers
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
      upload = UploadSpy.new([201, 200, 200], "")
      resource = Out.new(reader: reader, upload: upload)

      resource.call("/sources/path", @input_with_list)

      assert_equal(
        "https://myuser:abcde123456@bintray.com/api/v1/file_metadata/rabbitmq/community-plugins/built-package12345.ez",
        upload.uris.last
      )
      assert_equal(
        JSON.generate("list_in_downloads" => true),
        upload.contents.last
      )
      assert_equal(
        {"Content-Type" => "application/json"},
        upload.headers.last
      )
    end

    def test_emits_version_passed_to_it
      reader = ReaderStub.new(to_return: { "version" => "1.2.3" })
      retval = Out.new(reader: reader, upload: UploadSpy.new([201, 200])).
        call("/full/sources", @input)
      assert_equal({ "ref" => "1.2.3" }, retval["version"])
    end

    def test_result_of_put_is_placed_in_metadata
      resource = Out.new(
        reader: ReaderStub.new,
        upload: UploadSpy.new([200, 200], '{"result":"success"}')
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

    def test_failure_in_upload_raises_exception
      resource = Out.new(
        reader: ReaderStub.new,
        upload: UploadSpy.new.ordered_failures(true)
      )
      assert_raises(BintrayResource::Upload::FailureResponse) do
        resource.call("/sources/path", @input)
      end
    end

    def test_failure_in_downloads_list_raises_exception
      resource = Out.new(
        reader: ReaderStub.new,
        upload: UploadSpy.new([200, 200, 500]).ordered_failures(false, false, true)
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
