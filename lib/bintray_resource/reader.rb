module BintrayResource
  MultipleGlobMatches = Class.new(StandardError)
  NoGlobMatches = Class.new(StandardError)

  class Reader
    def read(glob)
      entries = Dir.glob(glob)
      if entries.size > 1
        raise MultipleGlobMatches
      elsif entries.empty?
        raise NoGlobMatches
      end
      { "contents" => File.read(entries.first),
        "basename" => File.basename(entries.first) }
    end
  end
end
