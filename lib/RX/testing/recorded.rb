# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

  # Record of a value including the virtual time it was produced on.
  class Recorded < Struct.new(:time, :value)

    def initialize(time, value)
      super
    end    

    def to_s
      "#{value} @ #{time}"
    end

  end
end