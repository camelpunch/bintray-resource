module BintrayResource
  MultipleGlobMatches = Class.new(StandardError)
  NoGlobMatches = Class.new(StandardError)

  class Reader
    def read(glob, version_regexp)
      entries = Dir.glob(glob)
      if entries.size > 1
        raise MultipleGlobMatches
      elsif entries.empty?
        raise NoGlobMatches
      end
      { "contents" => File.read(entries.first),
        "basename" => File.basename(entries.first),
        "version"  => version_from_filename(entries.first, version_regexp) }
    end

    private

    def version_from_filename(filename, regexp)
      Regexp.new(regexp) =~ filename
      Regexp.last_match[1]
    end
  end
end
