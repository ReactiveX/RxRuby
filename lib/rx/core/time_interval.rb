# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module Rx

  # Record of a value including the virtual time it was produced on.
  class TimeInterval < Struct.new(:interval, :value)

    def initialize(interval, value)
      super
    end

    def to_s
      "(#{value})@(#{interval})"
    end

  end
end