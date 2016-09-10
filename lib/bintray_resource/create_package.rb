require 'json'

module BintrayResource
  class CreatePackage
    attr_reader :source, :params
    private :source, :params

    def initialize(source, params, reader_response)
      @source = source
      @params = params
    end

    def applicable?
      true
    end

    def http_method
      :post
    end

    def uri
      [ source.base_uri,
        "packages",
        source.subject,
        source.repo ].join("/")
    end

    def body
      JSON.generate(
        "name" => source.package,
        "licenses" => params.licenses,
        "vcs_url" => params.vcs_url
      )
    end

    def headers
      {'Content-Type' => 'application/json'}
    end
  end
end
