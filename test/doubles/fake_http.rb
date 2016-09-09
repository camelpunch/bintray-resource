require_relative '../../lib/bintray_resource/http_response'

module BintrayResource
  class FakeHttp
    ResponseCodesExhausted = Class.new(StandardError)

    attr_reader :uris, :contents, :headers, :http_methods

    def initialize(response_codes = [200], response_body = "")
      @response_codes = response_codes
      @response_body = response_body
      @uris = []
      @contents = []
      @headers = []
      @http_methods = []
    end

    def post(uri, content, headers)
      @uris << uri
      @contents << content
      @headers << headers
      @http_methods << :post
      raise ResponseCodesExhausted if @response_codes.empty?
      HttpResponse.new(@response_codes.shift, @response_body)
    end

    def put(uri, content, headers)
      @uris << uri
      @contents << content
      @headers << headers
      @http_methods << :put
      raise ResponseCodesExhausted if @response_codes.empty?
      HttpResponse.new(@response_codes.shift, @response_body)
    end
  end
end
