require 'json'
require 'ostruct'
require 'pathname'
require_relative 'create_package'
require_relative 'list_in_downloads'
require_relative 'source'
require_relative 'upload_content'

module BintrayResource
  class Out
    attr_reader :reader, :upload
    private :reader, :upload

    def initialize(reader:, upload:)
      @reader = reader
      @upload = upload
    end

    def call(sources_dir, opts)
      source = Source.new(opts["source"])
      params = OpenStruct.new(opts["params"])
      contents, basename, version = reader.read(
        Pathname(sources_dir).join(params.file).to_s,
        params.version_regexp
      ).values_at(*%w(contents basename version))

      responses = [
        CreatePackage.new(source, params),
        UploadContent.new(source, params, contents, version, basename),
        ListInDownloads.new(source, params, basename),
      ].select(&:applicable?).map { |datum|
        upload.call(
          datum.http_method,
          datum.uri,
          datum.body,
          datum.headers
        )
      }

      { "version"  => { "ref" => version },
        "metadata" => [{ "name" => "response",
                         "value" => responses[1].body }] }
    end
  end
end

