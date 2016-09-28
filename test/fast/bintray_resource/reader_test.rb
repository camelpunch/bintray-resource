require 'minitest/autorun'
require 'minitest/focus'
require 'pathname'
require 'tmpdir'
require_relative '../../../lib/bintray_resource/reader'
require_relative '../../doubles/reader_stub'

module BintrayResource
  class TestReader < Minitest::Test
    def setup
      @reader = Reader.new
    end

    def test_contract
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        File.write(path.join("myfile"), "single match")
        assert_kind_of Reader::Response, @reader.read(path.join("my*"), "(.*)")
      end
    end
  end

  class TestReaderStubEmpty < TestReader
    def setup
      @reader = ReaderStub.new
    end
  end

  class TestReaderStubPrimed < TestReader
    def setup
      @reader = ReaderStub.new(stub: {}, to_return: Reader::Response.new("", "", ""))
    end
  end

  class TestRealReader < TestReader
    def test_reads_file_with_single_glob_match
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        File.write(path.join("myfile"), "single match")
        result = Reader.new.read(path.join("my*"), "(.*)")
        assert_equal "single match", result.contents
        assert_equal "myfile", result.filename
      end
    end

    def test_pulls_version_from_first_regexp_group
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        path.join("my-1.2.3").mkpath
        File.write(path.join("my-1.2.3", "file"), "single match")
        result = Reader.new.read(path.join("my*/*"), "my-(.*)/file")
        assert_equal("1.2.3", result.version)
      end
    end

    def test_raises_exception_when_regexp_does_not_match
      Dir.mktmpdir do |dir|
        Dir.chdir(dir)
        subdir = Pathname('versioned-deb')
        subdir.mkpath
        subdir.join('rabbitmq-server_3.6.5-1_someextrawords.deb').write("stuff")
        bad_regexp = "versioned-deb/rabbitmq-server-(.*)-[0-9]+.deb"
        assert_raises(Reader::NoRegexpMatch) do
          Reader.new.read("versioned-deb/*.deb", bad_regexp)
        end
      end
    end

    def test_raises_exception_when_regexp_has_no_matching_groups
      Dir.mktmpdir do |dir|
        Dir.chdir(dir)
        subdir = Pathname('versioned-deb')
        subdir.mkpath
        subdir.join('rabbitmq-server_3.6.5-1_someextrawords.deb').write("stuff")
        bad_regexp = "versioned-deb/rabbitmq-server.*"
        assert_raises(Reader::NoRegexpGroups) do
          Reader.new.read("versioned-deb/*.deb", bad_regexp)
        end
      end
    end

    def test_raises_exception_when_glob_has_multiple_matches
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        File.write(path.join("file1"), "1st match")
        File.write(path.join("file2"), "2nd match")
        assert_raises(Reader::MultipleGlobMatches) do
          Reader.new.read(path.join("file?"), ".*")
        end
      end
    end

    def test_raises_exception_when_glob_has_no_matches
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        assert_raises(Reader::NoGlobMatches) do
          Reader.new.read(path.join("non-existent-*"), ".*")
        end
      end
    end
  end
end
