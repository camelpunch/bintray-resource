require 'json'
require 'pathname'

module BintrayResource
  FailureResponse = Class.new(StandardError)

  class Out
    def initialize(reader:, http:)
      @reader = reader
      @http = http
    end

    attr_reader :reader, :http
    private :reader, :http

    def call(sources_dir, opts)
      subject, repo, package, version,
        api_version, username, api_key = opts["source"].
        values_at(*%w(subject repo package version
                  api_version username api_key))
      file, publish      = opts["params"].values_at(*%w(file publish))

      full_glob          = Pathname(sources_dir).join(file)
      uri_publish        = publish ? "1" : "0"
      contents, basename = reader.read(full_glob.to_s).
        values_at(*%w(contents basename))

      response = http.put(
        "https://#{username}:#{api_key}@bintray.com/api/#{api_version}" +
        "/content/#{subject}/#{repo}/#{package}/#{version}" +
        "/#{basename}?publish=#{uri_publish}",
        contents
      )

      raise FailureResponse, response.body if response.code >= 400

      { "version"  => { "ref" => version },
        "metadata" => [{ "name" => "response",
                         "value" => response.body }] }
    end
  end
end

