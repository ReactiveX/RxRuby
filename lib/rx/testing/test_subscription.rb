# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

  # Records information about subscriptions to and unsubscriptions from observable sequences.
  class TestSubscription < Struct.new(:subscribe, :unsubscribe)

    FIXNUM_MAX = (2**(0.size * 8 -2) -1)

    def initialize(subscribe, unsubscribe = FIXNUM_MAX)
      super
    end

    def inifinite?
      unsubscribe == FIXNUM_MAX
    end
    
    def to_s
      "#{subscribe}, #{infinite? ? 'Infinite' : unsubscribe}"
    end
  end
end