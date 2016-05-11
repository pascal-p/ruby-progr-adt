require 'rake/testtask'
# require 'rake/packagetask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/bin/test*.rb']
  t.verbose = true
end

# Rake::TestTask.new do |t|
#   t.libs << 'test'
#   t.name = 'testclock'
#   t.test_files = FileList['test/bin/test*clock*.rb']
#   t.verbose = true
# end

# running test
desc "Run tests"
task :default => :test

#desc "Run clock test"
#task :testclock

