#!/usr/bin/env rake

#require "bundler/gem_tasks"

#require 'rspec/core/rake_task'
#RSpec::Core::RakeTask.new=end

require 'rake/clean'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/test*.rb']
end