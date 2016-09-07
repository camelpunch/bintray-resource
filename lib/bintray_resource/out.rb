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
      list_in_downloads(source, params, basename)

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

    def list_in_downloads(source, params, basename)
      if params.list_in_downloads
        list_response = http.put(
          source.base_uri +
          "/file_metadata/#{source.subject}/#{source.repo}/#{basename}",
          JSON.generate("list_in_downloads" => true),
          "Content-Type" => "application/json"
        )
        raise FailureResponse, list_response.body if list_response.code >= 400
      end
    end

    def uri_bool(bool)
      bool ? "1" : "0"
    end
  end

  class Source
    attr_reader :api_key, :api_version, :package, :repo, :subject, :username

    def initialize(opts)
      @api_key, @api_version, @package, @repo, @subject, @username =
        opts.values_at(*%w(api_key api_version package repo subject username))
    end

    def base_uri
      "https://#{username}:#{api_key}@bintray.com/api/#{api_version}"
    end
  end
end

