require_relative '../../lib/bintray_resource/reader'

module BintrayResource
  class ReaderStub
    def initialize(stub: {}, to_return: Reader::Response.new("", "", ""))
      @stubs = stub
      @read_return = to_return
    end

    def read(actual_glob, actual_regexp)
      if @stubs.empty? || actual_glob == @stubs[:glob] && actual_regexp == @stubs[:regexp]
        @read_return
      else
        Reader::Response.new(
          "notstubbed",
          "notstubbed",
          "notstubbed"
        )
      end
    end
  end
end
