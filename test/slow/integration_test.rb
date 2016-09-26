require 'json'
require 'minitest/autorun'
require 'open-uri'
require 'pathname'
require 'securerandom'
require 'tmpdir'
require 'net/http'

require_relative '../../lib/bintray_resource'

# Warning! This test will delete your repo before it begins.
class TestSlowIntegration < Minitest::Test
  def setup
    @username = ENV.fetch('BINTRAY_USERNAME')
    @api_key = ENV.fetch('BINTRAY_API_KEY')
    @subject = ENV.fetch('BINTRAY_SUBJECT')
    @repo = ENV.fetch('BINTRAY_REPO')

    http = Net::HTTP.new("api.bintray.com", 443)
    http.use_ssl = true
    path = "/repos/#{@subject}/#{@repo}"

    puts "Deleting #{@repo}..."
    send_request(http, Net::HTTP::Delete.new(path))

    puts "Creating #{@repo}..."
    post_request = Net::HTTP::Post.new(path)
    post_request.body = JSON.generate({})
    send_request(http, post_request)

  rescue KeyError => e
    skip "Skipping slow integration test (missing env vars).\n#{e.message}"
  end

  def send_request(http, request)
    request.basic_auth(@username, @api_key)
    request['Content-Type'] = 'application/json'
    http.request(request)
  end

  def test_create_published_package_in_download_list
    exec_path = Pathname(__dir__).join("../../out")
    generated_name = SecureRandom.uuid

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        tmpdir        = Pathname(dir)
        input         = tmpdir.join("some-input")
        version       = "1.2.3"
        version_path  = input.join("1.2.3")
        path          = version_path.join(generated_name)

        version_path.mkpath
        path.write("testcontent")

        input = {
          "source" => {
            "username" => @username,
            "api_key" => @api_key,
            "subject" => @subject,
            "repo" => @repo,
            "package" => generated_name,
          },
          "params" => {
            "file" => "some-input/1.2.3/*",
            "version_regexp" => "some-input/(.*)/#{generated_name}",
            "publish" => true,
            "list_in_downloads" => false, # takes too long at Bintray's end
            "licenses" => ["Mozilla-1.1"],
            "vcs_url" => "https://example.com/foo/bar",
          }
        }
        out = BintrayResource::Out.new(
          reader: BintrayResource::Reader.new,
          upload: BintrayResource::Upload.new(
            http: BintrayResource::Http.new
          )
        )
        data = out.call(dir, input)

        assert_equal({ "version"  => { "ref" => "1.2.3" },
                       "metadata" => [{ "name" => "response",
                                        "value" => '{"message":"success"}' }] }, data)
      end
    end
  end
end
