require 'uri'
require_relative 'sleeper'

module BintrayResource
  class Upload
    FailureResponse = Class.new(StandardError)
    SUCCESS = (0..399)
    ALREADY_EXISTS = 409

    attr_reader :http, :sleeper, :retries, :backoff_factor
    private :http, :sleeper, :retries, :backoff_factor

    def initialize(http:, sleeper: Sleeper.new, retries: 10, backoff_factor: 2)
      @http = http
      @sleeper = sleeper
      @retries = retries
      @backoff_factor = backoff_factor
    end

    def call(method, uri, contents,
             headers,
             try: 1,
             sleep_time: 1)
      response = http.public_send(method, uri, contents, headers)
      case response.code
      when SUCCESS, ALREADY_EXISTS
        response
      else
        raise_failure(method, uri, response) if try == retries
        sleeper.sleep(sleep_time)
        call(method, uri, contents, headers,
             try: try + 1, sleep_time: sleep_time * backoff_factor)
      end
    end

    private

    def raise_failure(method, uri, response)
      parsed_uri = URI.parse(uri)
      raise FailureResponse, "#{method} to #{parsed_uri.host}#{parsed_uri.path}?#{parsed_uri.query} failed with #{response.code}:\n#{response.body}"
    end
  end
end
