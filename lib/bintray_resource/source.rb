module BintrayResource
  class ReaderStub
    def initialize(stub: {}, to_return: {})
      @stubs = stub
      @read_return = to_return
    end

    def read(actual_glob, actual_regexp)
      if @stubs.empty? || actual_glob == @stubs[:glob] && actual_regexp == @stubs[:regexp]
        @read_return
      else
        {
          "basename" => "notstubbed",
          "contents" => "notstubbed",
          "version" => "notstubbed",
        }
      end
    end
  end
end
