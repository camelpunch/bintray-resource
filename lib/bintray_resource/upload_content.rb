module BintrayResource
  class UploadContent
    attr_reader :source, :params, :contents, :version, :filename
    private :source, :params, :contents, :version, :filename

    def initialize(source, params, reader_response)
      @source = source
      @params = params
      @contents = reader_response.contents
      @version = reader_response.version
      @filename = reader_response.filename
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
        "#{filename}#{matrix_params}" ].join("/")
    end

    def body
      contents
    end

    def headers
      if params.gpg_passphrase
        default_headers.merge('X-GPG-PASSPHRASE' => params.gpg_passphrase)
      else
        default_headers
      end
    end

    private

    def matrix_params
      matrixify(matrix_kvs)
    end

    def matrix_kvs
      default_matrix_kvs.merge(params.prefixed_params)
    end

    def matrixify(kvs)
      kvs.reduce("") { |acc, (key, value)|
        acc + ";#{key}=#{join(value)}"
      }
    end

    def join(val)
      val.respond_to?(:join) ? val.join(',') : val
    end

    def default_matrix_kvs
      {"publish" => uri_bool(params.publish)}
    end

    def default_headers
      {'Content-Type' => 'application/octet-stream'}
    end

    def uri_bool(bool)
      bool ? "1" : "0"
    end
  end
end
