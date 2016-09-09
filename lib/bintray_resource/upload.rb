require_relative 'sleeper'

module BintrayResource
  class Upload
    FailureResponse = Class.new(StandardError)
    SUCCESS = (0..399)
    ALREADY_EXISTS = 409
    FAILURE = (400..499)

    attr_reader :http, :sleeper, :retries
    private :http, :sleeper, :retries

    def initialize(http:, sleeper: Sleeper.new, retries: 10)
      @http = http
      @sleeper = sleeper
      @retries = retries
    end

    def call(uri, contents,
             headers = {"Content-Type" => "application/octet-stream"},
             try: 1,
             sleep_time: 1)
      response = http.put(uri, contents, headers)
      case response.code
      when SUCCESS, ALREADY_EXISTS
        response
      else
        raise_failure("PUT", uri, response) if try == retries
        sleeper.sleep(sleep_time)
        call(
          uri, contents, headers,
          try: try + 1, sleep_time: sleep_time * 2
        )
      end
    end

    private

    def raise_failure(method, uri, response)
      raise FailureResponse, "#{method} to #{uri} failed with #{response.code}:\n#{response.body}"
    end
  end
end
