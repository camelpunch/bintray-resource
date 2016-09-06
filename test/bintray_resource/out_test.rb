require 'minitest/autorun'
require_relative '../../lib/bintray_resource/out'
require_relative '../../lib/bintray_resource/http_response'

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
    end

    def test_uploads_contents_of_file
      reader = ReaderStub.new(
        stub: {
          glob: "/sources/path/my-source/built-*.ez",
          regexp:  "my-source/(.*)/built-.*",
        },
        to_return: {
          "basename"  => "built-package.ez",
          "contents"  => "my-sweet-file-contents",
          "version"   => "3.6.5",
        }
      )
      http = FakeHttp.new
      resource = Out.new(reader: reader, http: http)

      resource.call("/sources/path", @input)

      assert_equal(
        "https://myuser:abcde123456@bintray.com/api/v1/content/rabbitmq/community-plugins/rabbitmq_clusterer/3.6.5/built-package.ez?publish=1",
        http.received_uri
      )
      assert_equal(
        "my-sweet-file-contents",
        http.received_content
      )
    end

    def test_emits_version_passed_to_it
      reader = ReaderStub.new(to_return: { "version" => "1.2.3" })
      retval = Out.new(reader: reader, http: FakeHttp.new).
        call("/full/sources", @input)
      assert_equal({ "ref" => "1.2.3" }, retval["version"])
    end

    def test_result_of_put_is_placed_in_metadata
      resource = Out.new(
        reader: ReaderStub.new(
          stub: {
            glob: "/sources/path/my-source/built-package.ez",
            regexp: "my-source/(.*)/built-.*",
          },
          to_return: {
            "basename" => "",
            "contents" => "",
            "version" => "",
          }
        ),
        http: FakeHttp.new(200, '{"result":"success"}')
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

    def test_failure_raises_exception
      resource = Out.new(
        reader: ReaderStub.new,
        http: FakeHttp.new(400, '{"result":"failure"}')
      )
      assert_raises(BintrayResource::FailureResponse) do
        resource.call("/sources/path", @input)
      end
    end

    class FakeHttp
      attr_reader :received_uri, :received_content

      def initialize(response_code = 200, response_body = "")
        @response_code = response_code
        @response_body = response_body
      end

      def put(uri, content)
        @received_uri = uri
        @received_content = content
        HttpResponse.new(@response_code, @response_body)
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
