require 'simplecov'

SimpleCov.start do
  coverage_dir '.coverage'
  add_filter 'test/'
end

require 'minitest/autorun'
require 'rx'
