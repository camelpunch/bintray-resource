require 'minitest/autorun'
require 'minitest/focus'
require_relative '../../../lib/bintray_resource/out'
require_relative '../../../lib/bintray_resource/upload'
require_relative '../../doubles/fake_http'
require_relative '../../doubles/upload_spy'
require_relative '../../doubles/reader_stub'

module BintrayResource
  class TestOut < Minitest::Test
    def setup
      @input = {
        "source" => {
          "api_key"         => "abcde123456",
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
        stub: { glob: "/sources/path/my-source/built-*.ez", regexp: "my-source/(.*)/built-.*", },
        to_return: Reader::Response.new("built-package12345.ez",
                                        "3.6.5",
                                        "my-sweet-file-contents")
      )
      upload = UploadSpy.new([201, 200], "")
      resource = Out.new(reader: reader, upload: upload)

      resource.call("/sources/path", @input)

      expected_uris = %w(
        https://myuser:abcde123456@bintray.com/api/v1/packages/rabbitmq/community-plugins
        https://myuser:abcde123456@bintray.com/api/v1/content/rabbitmq/community-plugins/rabbitmq_clusterer/3.6.5/built-package12345.ez?publish=1
      )
      assert_equal(expected_uris, upload.uris)
      assert_equal(%i(post put), upload.http_methods)

      expected_json = JSON.generate("name" => "rabbitmq_clusterer",
                                    "licenses" => ["Mozilla-1.1"],
                                    "vcs_url" => "https://github.com/rabbitmq/rabbitmq-clusterer")
      assert_equal([ expected_json, "my-sweet-file-contents" ], upload.contents)

      expected_headers = [ {"Content-Type" => "application/json"},
                           {"Content-Type" => "application/octet-stream"}, ]
      assert_equal(expected_headers, upload.headers)
    end

    def test_uploads_and_makes_available_in_downloads_list
      reader = ReaderStub.new(
        stub: { glob: "/sources/path/my-source/built-*.ez", regexp: "my-source/(.*)/built-.*" },
        to_return: Reader::Response.new("built-package12345.ez",
                                        "3.6.5",
                                        "my-sweet-file-contents")
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
      reader = ReaderStub.new(to_return: Reader::Response.new("", "1.2.3", ""))
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
  end
end
