require 'minitest/autorun'
require 'simplecov'

SimpleCov.start do
  coverage_dir '.coverage'
  add_filter 'test/'
end

require 'rx'
