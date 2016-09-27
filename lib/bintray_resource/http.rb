require 'net/http'
require 'uri'
require_relative 'http_response'

module BintrayResource
  class Http
    attr_reader :logger
    private     :logger

    def initialize(logger)
      @logger = logger
    end

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

      logger.log("#{method.upcase} #{uri}")
      logger.log(string_kvs(headers))
      response = Net::HTTP.start(u.hostname, u.port, use_ssl: u.scheme == 'https') {|http|
        http.request(request)
      }
      logger.log(response.code)
      logger.log(response.body)
      HttpResponse.new(response.code.to_i, response.body)
    end

    private

    def string_kvs(headers)
      headers.
        map {|k, v| "#{k}: #{v}"}.
        join("\n")
    end
  end
end
