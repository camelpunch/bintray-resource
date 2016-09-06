require 'minitest/autorun'
require 'json'
require_relative '../../lib/bintray_resource/http'

module BintrayResource
  class TestHttp < Minitest::Test
    def test_put_success_returns_code
      http = Http.new
      response = http.put("http://httpbin.org/put", "foobar")
      assert_equal 200, response.code
    end

    def test_put_success_returns_parsed_body
      http = Http.new
      response = http.put("http://httpbin.org/put", "foobar")
      assert_equal "httpbin.org", JSON.parse(response.body)["headers"]["Host"]
    end
  end
end
