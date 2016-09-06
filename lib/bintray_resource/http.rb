require 'faraday'
require 'uri'
require_relative 'http_response'

module BintrayResource
  class Http
    def put(uri, contents)
      u = URI.parse(uri)
      conn = Faraday.new("#{u.scheme}://#{u.host}")
      conn.basic_auth(u.user, u.password)
      response = conn.put("#{u.path}?#{u.query}", contents)
      HttpResponse.new(response.status, response.body)
    end
  end
end
