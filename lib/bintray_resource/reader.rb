module BintrayResource
  MultipleGlobMatches = Class.new(StandardError)

  class Reader
    def read(glob)
      entries = Dir.glob(glob)
      raise MultipleGlobMatches if entries.size > 1
      File.read(entries.first)
    end
  end
end
