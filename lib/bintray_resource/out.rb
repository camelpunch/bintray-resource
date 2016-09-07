require 'json'
require 'pathname'
require 'ostruct'
require_relative 'source'

module BintrayResource
  FailureResponse = Class.new(StandardError)

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
      upload_response = http.put(
        source.base_uri +
        "/content/#{source.subject}/#{source.repo}/#{source.package}/#{version}" +
        "/#{basename}?publish=#{uri_bool(params.publish)}",
        contents,
        {"Content-Type" => "application/octet-stream"}
      )
      raise FailureResponse, upload_response.body if upload_response.code >= 400
      upload_response
    end

    def list_in_downloads(source, basename)
      uri = source.base_uri + "/file_metadata/#{source.subject}/#{source.repo}/#{basename}"
      list_response = http.put(
        uri,
        JSON.generate("list_in_downloads" => true),
        "Content-Type" => "application/json"
      )
      raise FailureResponse, "PUT to #{uri} failed:\n#{list_response.body}" if list_response.code >= 400
      list_response
    end

    def uri_bool(bool)
      bool ? "1" : "0"
    end
  end
end

