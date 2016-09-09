require 'rake/testtask'

Rake::TestTask.new(:fast) do |t|
  t.pattern = "test/fast/**/*_test.rb"
end

Rake::TestTask.new(:slow) do |t|
  t.pattern = "test/slow/**/*_test.rb"
end

desc "Run all tests"
task test: [:fast, :slow]

task(build: :test) do |t|
  sh %Q{docker build . -t camelpunch/bintray-resource}
end

task(push: :build) do |t|
  sh %Q{docker push camelpunch/bintray-resource}
end

task default: :test
