require 'rx_ruby/operators/aggregates.rb'

module RxRuby
  module Observable
    alias :aggregate :reduce
  end
end
