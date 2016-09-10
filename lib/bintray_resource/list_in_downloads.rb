require 'json'

module BintrayResource
  class ListInDownloads
    attr_reader :source, :params, :filename
    private :source, :params, :filename

    def initialize(source, params, filename)
      @source = source
      @params = params
      @filename = filename
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
