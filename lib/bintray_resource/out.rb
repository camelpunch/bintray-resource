require 'json'
require 'pathname'
require 'ostruct'
require_relative 'source'

module BintrayResource
  FailureResponse = Class.new(StandardError)
  SUCCESS = (0..399)
  ALREADY_EXISTS = 409

  class Out
    def initialize(reader:, http:)
      @reader = reader
      @http = http
    end

    attr_reader :reader, :http
    private :reader, :http

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
      upload_response = http.put(
        uri,
        contents,
        {"Content-Type" => "application/octet-stream"}
      )
      case upload_response.code
      when SUCCESS, ALREADY_EXISTS
        upload_response
      else
        raise_failure("PUT", uri, upload_response)
      end
    end

    def list_in_downloads(source, basename)
      uri = source.base_uri + "/file_metadata/#{source.subject}/#{source.repo}/#{basename}"
      list_response = http.put(
        uri,
        JSON.generate("list_in_downloads" => true),
        "Content-Type" => "application/json"
      )
      raise_failure("PUT", uri, list_response) unless SUCCESS === list_response.code
      list_response
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

