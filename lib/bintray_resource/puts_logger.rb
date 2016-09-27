module BintrayResource
  class PutsLogger
    def initialize(output)
      @output = output
    end

    def log(line)
      @output.puts(line)
    end
  end
end
