module BintrayResource
  class Source
    attr_reader :api_key, :api_version, :package, :repo, :subject, :username

    def initialize(opts)
      @api_key, @api_version, @package, @repo, @subject, @username =
        opts.values_at(*%w(api_key api_version package repo subject username))
    end

    def base_uri
      "https://#{username}:#{api_key}@bintray.com/api/#{api_version}"
    end
  end
end
