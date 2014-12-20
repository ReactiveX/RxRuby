require 'rx/operators/aggregates.rb'

module RX
  module Observable
    alias :aggregate :reduce
  end
end
