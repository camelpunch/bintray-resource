module BintrayResource
  class Params
    attr_reader :file, :version_regexp, :list_in_downloads, :licenses, :vcs_url, :publish
    attr_reader :raw_input
    private     :raw_input

    def initialize(kvs)
      @file, @version_regexp, @list_in_downloads, @licenses, @vcs_url, @publish =
        kvs.values_at(*%w(file version_regexp list_in_downloads licenses vcs_url publish))
      @raw_input = kvs
    end

    def prefixed_params
      prefixes.reduce({}) { |acc, (config_key, uri_prefix)|
        data = raw_input.fetch(config_key, {})
        acc.merge(prefix_keys(uri_prefix, data))
      }
    end

    private

    def prefix_keys(prefix, h)
      h.reduce({}) { |acc, (k, v)|
        acc.merge("#{prefix}_#{k}" => v)
      }
    end

    def prefixes
      { "debian" => "deb" }
    end
  end
end
