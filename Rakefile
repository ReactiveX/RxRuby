#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/clean'
require 'rake/testtask'

task default: :test

Rake::TestTask.new do |task|
  task.libs.unshift(File.expand_path('../test', __FILE__))
  task.test_files = FileList['test/**/test*.rb']
end
