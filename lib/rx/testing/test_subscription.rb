# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module Rx

  # Records information about subscriptions to and unsubscriptions from observable sequences.
  class TestSubscription < Struct.new(:subscribe, :unsubscribe)

    FIXNUM_MAX = Float::MAX.to_i

    def initialize(subscribe, unsubscribe = FIXNUM_MAX)
      super
    end

    def infinite?
      unsubscribe == FIXNUM_MAX
    end
    
    def to_s
      "#{subscribe}, #{infinite? ? 'Infinite' : unsubscribe}"
    end
  end
end