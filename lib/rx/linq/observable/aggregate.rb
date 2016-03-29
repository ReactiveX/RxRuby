require 'rx/operators/aggregates.rb'

module Rx
  module Observable
    alias :aggregate :reduce
  end
end
