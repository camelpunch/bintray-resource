require 'json'
require 'ostruct'
require 'pathname'
require_relative 'sleeper'
require_relative 'source'
require_relative 'upload'

module BintrayResource
  FailureResponse = Class.new(StandardError)
  SUCCESS = (0..399)
  ALREADY_EXISTS = 409
  FAILURE = (400..499)

  class Out
    attr_reader :reader, :http, :sleeper, :retries
    private :reader, :http, :sleeper, :retries

    def initialize(reader:, http:, sleeper: Sleeper.new, retries: 10)
      @reader = reader
      @http = http
      @retries = retries
      @sleeper = sleeper
    end

    def call(sources_dir, opts)
      source = Source.new(opts["source"])
      params = OpenStruct.new(opts["params"])
      contents, basename, version = reader.read(
        Pathname(sources_dir).join(params.file).to_s,
        params.version_regexp
      ).values_at(*%w(contents basename version))

      upload = Upload.new(http, sleeper, retries)
      upload_response = upload.call(
        upload_uri(source, version, basename, params),
        contents
      )

      if params.list_in_downloads
        upload.call(
          source.base_uri + "/file_metadata/#{source.subject}/#{source.repo}/#{basename}",
          JSON.generate("list_in_downloads" => true),
          "Content-Type" => "application/json"
        )
      end

      { "version"  => { "ref" => version },
        "metadata" => [{ "name" => "response",
                         "value" => upload_response.body }] }
    end

    private

    def upload_uri(source, version, filename, params)
      source.base_uri +
        "/content/#{source.subject}/#{source.repo}/#{source.package}/#{version}" +
        "/#{filename}?publish=#{uri_bool(params.publish)}"
    end

    def uri_bool(bool)
      bool ? "1" : "0"
    end
  end
end

