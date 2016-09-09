require 'minitest/autorun'
require 'pathname'
require 'tmpdir'
require_relative '../../../lib/bintray_resource/reader'

module BintrayResource
  class TestReader < Minitest::Test
    def test_reads_file_with_single_glob_match
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        File.write(path.join("myfile"), "single match")
        result = Reader.new.read(path.join("my*"), ".*")
        assert_equal "single match", result["contents"]
        assert_equal "myfile", result["basename"]
        assert_nil result["version"]
      end
    end

    def test_pulls_version_from_first_regexp_group
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        path.join("my-1.2.3").mkpath
        File.write(path.join("my-1.2.3", "file"), "single match")
        result = Reader.new.read(path.join("my*/*"), "my-(.*)/file")
        assert_equal("1.2.3", result["version"])
      end
    end

    def test_raises_exception_when_glob_has_multiple_matches
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        File.write(path.join("file1"), "1st match")
        File.write(path.join("file2"), "2nd match")
        assert_raises(MultipleGlobMatches) do
          Reader.new.read(path.join("file?"), ".*")
        end
      end
    end

    def test_raises_exception_when_glob_has_no_matches
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        assert_raises(NoGlobMatches) do
          Reader.new.read(path.join("non-existent-*"), ".*")
        end
      end
    end
  end
end
