require_relative '../../lib/bintray_resource/http_response'

module BintrayResource
  class FakeHttp
    ResponseCodesExhausted = Class.new(StandardError)

    attr_reader :put_uris, :put_contents, :put_headers

    def initialize(response_codes = [200], response_body = "")
      @response_codes = response_codes
      @response_body = response_body
      @put_uris = []
      @put_contents = []
      @put_headers = []
    end

    def put(uri, content, headers)
      @put_uris << uri
      @put_contents << content
      @put_headers << headers
      raise ResponseCodesExhausted if @response_codes.empty?
      HttpResponse.new(@response_codes.shift, @response_body)
    end
  end
end
