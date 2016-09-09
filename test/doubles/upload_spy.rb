require_relative '../../lib/bintray_resource/http_response'
require_relative '../../lib/bintray_resource/upload'
require_relative 'fake_http'

module BintrayResource
  class UploadSpy
    attr_reader :http

    def initialize(response_codes = [200], response_body = "")
      @http = FakeHttp.new(response_codes, response_body)
      @failures = []
    end

    def ordered_failures(*list)
      @failures = list
      self
    end

    def call(uri, content, headers = {})
      raise Upload::FailureResponse if @failures.shift
      http.put(uri, content, headers)
    end

    def headers
      http.headers
    end

    def contents
      http.contents
    end

    def uris
      http.uris
    end
  end
end
