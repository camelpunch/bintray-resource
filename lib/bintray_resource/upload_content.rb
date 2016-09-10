module BintrayResource
  class UploadContent
    attr_reader :source, :params, :contents, :version, :filename
    private :source, :params, :contents, :version, :filename

    def initialize(source, params, contents, version, filename)
      @source = source
      @params = params
      @contents = contents
      @version = version
      @filename = filename
    end

    def applicable?
      true
    end

    def http_method
      :put
    end

    def uri
      [ source.base_uri,
        "content",
        source.subject,
        source.repo,
        source.package,
        version,
        "#{filename}?publish=#{uri_bool(params.publish)}" ].join("/")
    end

    def body
      contents
    end

    def headers
      {'Content-Type' => 'application/octet-stream'}
    end

    private

    def uri_bool(bool)
      bool ? "1" : "0"
    end
  end
end
