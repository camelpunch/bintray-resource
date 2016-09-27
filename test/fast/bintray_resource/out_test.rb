require 'minitest/autorun'
require 'minitest/focus'
require_relative '../../../lib/bintray_resource/out'
require_relative '../../../lib/bintray_resource/upload'
require_relative '../../doubles/fake_http'
require_relative '../../doubles/upload_spy'
require_relative '../../doubles/reader_stub'

module BintrayResource
  class TestOut < Minitest::Test
    def test_create_and_upload
      reader = ReaderStub.new(
        stub: { glob: "/sources/path/my-source/built-*.ez", regexp: "my-source/(.*)/built-.*", },
        to_return: Reader::Response.new("built-package12345.ez",
                                        "3.6.5",
                                        "my-sweet-file-contents")
      )
      upload = UploadSpy.new([201, 200], "")
      resource = Out.new(reader: reader, upload: upload)

      resource.call("/sources/path", generic_input)

      expected_uris = [
        "#{expected_uri_prefix}/packages/#{subject}/#{repo}",
        "#{expected_uri_prefix}/content/#{subject}/#{repo}/#{package}/3.6.5/built-package12345.ez;publish=1",
      ]
      assert_equal(expected_uris, upload.uris)
      assert_equal(%i(post put), upload.http_methods)

      expected_json = JSON.generate("name" => package,
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

      resource.call("/sources/path", generic_input_with_list)

      assert_equal(
        "#{expected_uri_prefix}/file_metadata/#{subject}/#{repo}/built-package12345.ez",
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

    def test_debian_upload
      reader = ReaderStub.new(
        stub: { glob: "/sources/path/my-source/built-*.deb", regexp: "my-source/(.*)/built-.*" },
        to_return: Reader::Response.new("built-package12345.deb",
                                        "3.6.5",
                                        "my-sweet-file-contents")
      )
      upload = UploadSpy.new([201, 200], "")
      resource = Out.new(reader: reader, upload: upload)

      debian_input = generic_input.merge(
        "params" => generic_input["params"].merge(
          "file" => "my-source/built-*.deb",
          "debian" => {
            "distribution"  => %w(wheezy jessie),
            "component"     => %w(main contrib non-free),
            "architecture"  => %w(i386 amd64),
          }
        )
      )

      resource.call("/sources/path", debian_input)

      expected_http_matrix_params = ";publish=1;deb_distribution=wheezy,jessie;deb_component=main,contrib,non-free;deb_architecture=i386,amd64"
      assert_equal("#{expected_uri_prefix}/content/#{subject}/#{repo}/#{package}/3.6.5/built-package12345.deb#{expected_http_matrix_params}",
                   upload.uris[1])
    end

    def test_emits_version_passed_to_it
      reader = ReaderStub.new(to_return: Reader::Response.new("", "1.2.3", ""))
      retval = Out.new(reader: reader, upload: UploadSpy.new([201, 200])).
        call("/full/sources", generic_input)
      assert_equal({ "ref" => "1.2.3" }, retval["version"])
    end

    def test_result_of_put_is_placed_in_metadata
      resource = Out.new(
        reader: ReaderStub.new,
        upload: UploadSpy.new([200, 200], '{"result":"success"}')
      )
      retval = resource.call("/sources/path", generic_input)

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
        resource.call("/sources/path", generic_input)
      end
    end

    def test_failure_in_downloads_list_raises_exception
      resource = Out.new(
        reader: ReaderStub.new,
        upload: UploadSpy.new([200, 200, 500]).ordered_failures(false, false, true)
      )
      assert_raises(BintrayResource::Upload::FailureResponse) do
        resource.call("/sources/path", generic_input_with_list)
      end
    end

    def generic_input
      {
        "source" => {
          "api_key"         => api_key,
          "package"         => package,
          "repo"            => repo,
          "subject"         => subject,
          "username"        => username,
        },
        "params" => {
          "file"            => "my-source/built-*.ez",
          "publish"         => true,
          "version_regexp"  => "my-source/(.*)/built-.*",
          "licenses"        => ["Mozilla-1.1"],
          "vcs_url"         => "https://github.com/rabbitmq/rabbitmq-clusterer",
        },
      }
    end

    def generic_input_with_list
      generic_input.merge(
        "params" => generic_input["params"].merge(
          "list_in_downloads" => true
        )
      )
    end

    def expected_uri_prefix
      "https://#{username}:#{api_key}@bintray.com/api/v1"
    end

    def username
      "myuser"
    end

    def api_key
      "abcde123456"
    end

    def package
      "rabbitmq_clusterer"
    end

    def subject
      "rabbitmq"
    end

    def repo
      "community-plugins"
    end
  end
end
