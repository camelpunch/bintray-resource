require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
end

task(build: :test) do |t|
  sh %Q{docker build . -t camelpunch/bintray-resource}
end

task(push: :build) do |t|
  sh %Q{docker push camelpunch/bintray-resource}
end

task default: :test
