require 'minitest/autorun'
require 'minitest/focus'
require 'json'
require_relative '../../../lib/bintray_resource/http'
require_relative '../../../test/doubles/fake_http'

module BintrayResource
  class TestHttp < Minitest::Test
    def setup
      @http = Http.new
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
  end

  class TestFakeHttp < TestHttp
    def setup
      @http = FakeHttp.new([200], '{"headers": {"Content-Type": "application/foofy", "Host": "httpbin.org"}}')
    end
  end
end
