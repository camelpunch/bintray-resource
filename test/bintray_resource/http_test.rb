require 'minitest/autorun'
require 'json'
require_relative '../../lib/bintray_resource/http'
require_relative '../../test/doubles/fake_http'

module BintrayResource
  class TestHttp < Minitest::Test
    def setup
      @http = Http.new
    end

    def test_put_success_returns_code
      response = @http.put("http://httpbin.org/put", "foobar", {})
      assert_equal 200, response.code
    end

    def test_put_success_returns_parsed_body
      response = @http.put("http://httpbin.org/put", "foobar", {})
      assert_equal "httpbin.org", JSON.parse(response.body)["headers"]["Host"]
    end
  end

  class TestFakeHttp < TestHttp
    def setup
      @http = FakeHttp.new([200], '{"headers": {"Host": "httpbin.org"}}')
    end
  end
end
