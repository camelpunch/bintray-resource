module BintrayResource
  class Source
    attr_reader :api_key, :package, :repo, :subject, :username

    API_VERSION = "v1"

    def initialize(opts)
      @api_key, @package, @repo, @subject, @username =
        opts.values_at(*%w(api_key package repo subject username))
    end

    def base_uri
      "https://#{username}:#{api_key}@bintray.com/api/#{API_VERSION}"
    end
  end
end
