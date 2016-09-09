require 'json'
require 'ostruct'
require 'pathname'
require_relative 'sleeper'
require_relative 'source'

module BintrayResource
  FailureResponse = Class.new(StandardError)
  SUCCESS = (0..399)
  ALREADY_EXISTS = 409
  FAILURE = (400..499)

  class Out
    def initialize(reader:, http:, sleeper: Sleeper.new, downloads_list_retries: 10)
      @reader = reader
      @http = http
      @downloads_list_retries = downloads_list_retries
      @sleeper = sleeper
    end

    attr_reader :reader, :http, :sleeper, :downloads_list_retries
    private :reader, :http, :sleeper, :downloads_list_retries

    def call(sources_dir, opts)
      source = Source.new(opts["source"])
      params = OpenStruct.new(opts["params"])
      contents, basename, version = reader.read(
        Pathname(sources_dir).join(params.file).to_s,
        params.version_regexp
      ).values_at(*%w(contents basename version))

      upload_response = upload(source, params, contents, basename, version)
      list_in_downloads(source, basename) if params.list_in_downloads

      { "version"  => { "ref" => version },
        "metadata" => [{ "name" => "response",
                         "value" => upload_response.body }] }
    end

    private

    def upload(source, params, contents, basename, version)
      uri = upload_uri(source, version, basename, params)
      response = http.put(
        uri,
        contents,
        {"Content-Type" => "application/octet-stream"}
      )
      case response.code
      when SUCCESS, ALREADY_EXISTS
        response
      else
        raise_failure("PUT", uri, response)
      end
    end

    def list_in_downloads(source, basename, try: 1, sleep_time: 1)
      uri = source.base_uri + "/file_metadata/#{source.subject}/#{source.repo}/#{basename}"
      response = http.put(
        uri,
        JSON.generate("list_in_downloads" => true),
        "Content-Type" => "application/json"
      )
      case response.code
      when SUCCESS
        response
      when FAILURE
        raise_failure("PUT", uri, response) if try == downloads_list_retries
        sleeper.sleep(sleep_time)
        list_in_downloads(
          source, basename,
          try: try + 1, sleep_time: sleep_time * 2
        )
      else
        raise_failure("PUT", uri, response)
      end
    end

    def uri_bool(bool)
      bool ? "1" : "0"
    end

    def upload_uri(source, version, filename, params)
      source.base_uri +
        "/content/#{source.subject}/#{source.repo}/#{source.package}/#{version}" +
        "/#{filename}?publish=#{uri_bool(params.publish)}"
    end

    def raise_failure(method, uri, response)
      raise FailureResponse, "#{method} to #{uri} failed with #{response.code}:\n#{response.body}"
    end
  end
end

