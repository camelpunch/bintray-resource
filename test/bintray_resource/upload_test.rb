require 'json'
require 'minitest/autorun'
require 'minitest/focus'
require_relative '../../lib/bintray_resource/upload'
require_relative '../doubles/fake_http'
require_relative '../doubles/upload_spy'

module BintrayResource
  class TestUpload < Minitest::Test
    def setup
      http = FakeHttp.new([200], '{"headers": {"Content-Type": "application/foofy", "Host": "httpbin.org"}}')
      @upload = Upload.new(http: http)
    end

    def test_contract
      response = @upload.call("http://httpbin.org/put", "foobar", {'some' => 'headers'})
      assert_equal "httpbin.org", JSON.parse(response.body)["headers"]["Host"]
    end
  end

  class TestRealUpload < TestUpload
    def setup
      @http = FakeHttp.new([200], '{"headers": {"Content-Type": "application/foofy", "Host": "httpbin.org"}}')
      @upload = Upload.new(http: @http)
    end

    def test_upload
      @upload.call("http://some/place", "my-sweet-file-contents", 'Content-Type' => 'application/octet-stream')

      assert_equal(
        %w(http://some/place),
        @http.put_uris
      )
      assert_equal(
        ["my-sweet-file-contents"],
        @http.put_contents
      )
      assert_equal(
        [{"Content-Type" => "application/octet-stream"}],
        @http.put_headers
      )
    end

    def test_400_failure_tries_again_with_backoff
      sleeper = SleeperSpy.new
      upload = Upload.new(
        http: FakeHttp.new([400, 400, 400, 200], ''),
        sleeper: sleeper
      )
      normal_response = {"version" => {"ref" => nil},
                         "metadata" => [{"name" => "response",
                                         "value" => ""}]}
      assert_equal(200, upload.call("http://sources/path", "content", {}).code)
      assert_equal([1, 2, 4], sleeper.sleeps)
    end

    def test_400_failure_has_retry_limit
      upload = Upload.new(
        http: FakeHttp.new([400, 400, 400], ''),
        sleeper: SleeperSpy.new,
        retries: 3
      )
      assert_raises(BintrayResource::Upload::FailureResponse) do
        upload.call("http://sources/path", "", {})
      end
    end

    def test_returns_conflict_failures_without_raising
      upload = Upload.new(http: FakeHttp.new([409], ""))
      response = upload.call("http://sources/path", "", {})
      assert_equal(409, response.code)
    end
  end

  class TestUploadSpy < TestUpload
    def setup
      @upload = UploadSpy.new([200], '{"headers": {"Content-Type": "application/foofy", "Host": "httpbin.org"}}')
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
end
