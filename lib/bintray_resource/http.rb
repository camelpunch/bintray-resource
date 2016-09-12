require 'net/http'
require 'uri'
require_relative 'http_response'

module BintrayResource
  class Http
    def post(*args)
      put_or_post(:post, *args)
    end

    def put(*args)
      put_or_post(:put, *args)
    end

    private

    def put_or_post(method, uri, contents, headers)
      u = URI.parse(uri)

      request = method == :put ? Net::HTTP::Put.new(u) : Net::HTTP::Post.new(u)
      request.basic_auth u.user, u.password
      request.body = contents
      headers.each_pair do |k, v|
        request[k] = v
      end

      response = Net::HTTP.start(u.hostname, u.port, use_ssl: u.scheme == 'https') {|http|
        http.request(request)
      }
      HttpResponse.new(response.code.to_i, response.body)
    end
  end
end
