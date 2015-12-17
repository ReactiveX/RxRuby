if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    coverage_dir '.coverage'
    add_filter 'test/'
  end
end

require 'minitest/autorun'
require 'rx_ruby'
