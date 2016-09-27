module BintrayResource
  class LogCollector
    attr_reader :logs

    def initialize
      @logs = []
    end

    def log(line)
      logs << line
    end
  end
end
