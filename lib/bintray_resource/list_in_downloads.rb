require 'json'

module BintrayResource
  class ListInDownloads
    attr_reader :source, :params, :filename, :version
    private :source, :params, :filename, :version

    def initialize(source, params, reader_response)
      @filename = reader_response.filename
      @params = params
      @source = source
      @version = reader_response.version
    end

    def applicable?
      params.list_in_downloads
    end

    def http_method
      :put
    end

    def uri
      [ source.base_uri,
        "file_metadata",
        source.subject,
        source.repo,
        version,
        filename ].join("/")
    end

    def body
      JSON.generate("list_in_downloads" => true)
    end

    def headers
      {'Content-Type' => 'application/json'}
    end
  end
end
