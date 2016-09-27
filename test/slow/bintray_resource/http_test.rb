require 'json'
require 'minitest/autorun'
require 'minitest/focus'
require_relative '../../../lib/bintray_resource/http'
require_relative '../../../test/doubles/fake_http'
require_relative '../../../test/doubles/log_collector'

module BintrayResource
  class TestHttp < Minitest::Test
    def setup
      @http = Http.new(LogCollector.new)
    end

    def test_post_success_returns_code
      response = @http.post("https://httpbin.org/post", "foobar", {})
      assert_equal 200, response.code
    end

    def test_post_success_returns_parsed_body
      response = @http.post("http://httpbin.org/post", "foobar", {'Content-Type' => 'application/foofy'})
      assert_equal "httpbin.org", JSON.parse(response.body)["headers"]["Host"]
      assert_equal "application/foofy", JSON.parse(response.body)["headers"]["Content-Type"]
    end

    def test_put_success_returns_code
      response = @http.put("http://httpbin.org/put", "foobar", {})
      assert_equal 200, response.code
    end

    def test_put_success_returns_parsed_body
      response = @http.put("http://httpbin.org/put", "foobar", {'Content-Type' => 'application/foofy'})
      assert_equal "httpbin.org", JSON.parse(response.body)["headers"]["Host"]
      assert_equal "application/foofy", JSON.parse(response.body)["headers"]["Content-Type"]
    end

    focus
    def test_logging
      log_collector = LogCollector.new
      @http = Http.new(log_collector)
      @http.post("https://httpbin.org/post", "foo", "Content-Type" => "application/json")
      @http.put("https://httpbin.org/put", "bar", {})

      assert_equal [%Q(POST https://httpbin.org/post),
                    %Q(Content-Type: application/json),
                    "200"], log_collector.logs[0..2]
      assert_equal "foo", JSON.parse(log_collector.logs[3])["data"]
    end
  end

  class TestFakeHttp < TestHttp
    def setup
      @http = FakeHttp.new([200], '{"headers": {"Content-Type": "application/foofy", "Host": "httpbin.org"}}')
    end
  end
end
