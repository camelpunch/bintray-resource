require 'json'
require 'pathname'
require_relative 'create_package'
require_relative 'list_in_downloads'
require_relative 'params'
require_relative 'source'
require_relative 'upload_content'

module BintrayResource
  class Out
    attr_reader :reader, :upload
    private :reader, :upload

    PIPELINE = [CreatePackage, UploadContent, ListInDownloads]

    def initialize(reader:, upload:)
      @reader = reader
      @upload = upload
    end

    def call(sources_dir, opts)
      source = Source.new(opts["source"])
      params = Params.new(opts["params"])
      reader_response = reader.read(
        Pathname(sources_dir).join(params.file).to_s,
        params.version_regexp
      )

      responses = PIPELINE.
        map { |k| k.new(source, params, reader_response) }.
        select(&:applicable?).
        map { |datum|
          upload.call(
            datum.http_method,
            datum.uri,
            datum.body,
            datum.headers
          )
        }

      { "version"  => { "ref" => reader_response.version },
        "metadata" => [{ "name" => "response",
                         "value" => responses[1].body }] }
    end
  end
end

