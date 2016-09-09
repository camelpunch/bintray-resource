require 'json'
require 'ostruct'
require 'pathname'
require_relative 'source'

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

      upload.call(
        :post,
        create_uri(source),
        JSON.generate("name" => source.package,
                      "licenses" => params.licenses,
                      "vcs_url" => params.vcs_url),
        'Content-Type' => 'application/json'
      )

      upload_response = upload.call(
        :put,
        upload_uri(source, version, basename, params),
        contents,
        'Content-Type' => 'application/octet-stream'
      )

      if params.list_in_downloads
        upload.call(
          :put,
          list_in_downloads_uri(source, basename),
          JSON.generate("list_in_downloads" => true),
          "Content-Type" => "application/json"
        )
      end

      { "version"  => { "ref" => version },
        "metadata" => [{ "name" => "response",
                         "value" => upload_response.body }] }
    end

    private

    def create_uri(source)
      [ source.base_uri,
        "packages",
        source.subject,
        source.repo ].join("/")
    end

    def upload_uri(source, version, filename, params)
      [ source.base_uri,
        "content",
        source.subject,
        source.repo,
        source.package,
        version,
        "#{filename}?publish=#{uri_bool(params.publish)}" ].join("/")
    end

    def list_in_downloads_uri(source, basename)
      [ source.base_uri,
        "file_metadata",
        source.subject,
        source.repo,
        basename ].join("/")
    end

    def uri_bool(bool)
      bool ? "1" : "0"
    end
  end
end

