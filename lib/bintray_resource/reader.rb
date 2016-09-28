module BintrayResource
  class Reader
    class Response
      attr_reader :filename, :version, :contents

      def initialize(filename, version, contents)
        @filename = filename
        @version = version
        @contents = contents
      end
    end

    MultipleGlobMatches = Class.new(StandardError)
    NoGlobMatches = Class.new(StandardError)

    def read(glob, version_regexp)
      entries = Dir.glob(glob)
      if entries.size > 1
        raise MultipleGlobMatches
      elsif entries.empty?
        raise NoGlobMatches
      end
      Response.new(
        File.basename(entries.first),
        version_from_filename(entries.first, version_regexp),
        File.read(entries.first),
      )
    end

    private

    def version_from_filename(filename, regexp)
      Regexp.new(regexp) =~ filename
      Regexp.last_match[1]
    end
  end
end
