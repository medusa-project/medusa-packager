require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << File.expand_path('test')
  t.pattern = 'test/*_test.rb'
end

desc 'Run tests'
task :default => :test
