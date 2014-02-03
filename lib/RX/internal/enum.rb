# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX
  class Enum

    private

    def self.enum_attr(name, num)
      name = name.to_s

      define_method(name + '?') do
        @attrs & num != 0
      end

      define_method(name + '=') do |set|
        if set
          @attrs |= num
        else
          @attrs &= ~num
        end
      end
    end

    public

    def initialize(attrs = 0)
      @attrs = attrs
    end

    def to_i
      @attrs
    end
  end
end