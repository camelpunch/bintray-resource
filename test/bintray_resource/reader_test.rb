require 'minitest/autorun'
require 'pathname'
require 'tmpdir'
require_relative '../../lib/bintray_resource/reader'

module BintrayResource
  class TestReader < Minitest::Test
    def test_reads_file_without_glob
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        File.write(path.join("myfile"), "my contents")
        assert_equal "my contents", Reader.new.read(path.join("myfile"))
      end
    end

    def test_reads_file_with_single_glob_match
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        File.write(path.join("myfile"), "single match")
        assert_equal "single match", Reader.new.read(path.join("my*"))
      end
    end

    def test_raises_exception_when_glob_has_multiple_matches
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        File.write(path.join("file1"), "1st match")
        File.write(path.join("file2"), "2nd match")
        assert_raises(MultipleGlobMatches) do
          Reader.new.read(path.join("file?"))
        end
      end
    end
  end
end
