# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX
  # Represents a disposable resource whose disposal invocation will be scheduled on the specified scheduler
  class ScheduledDisposable

    attr_reader :scheduler, :disposable

    def initialize(scheduler, subscription)
      raise 'disposable cannot be nil' unless subscription
      raise 'scheduler cannot be nil' unless scheduler

      @scheduler = scheduler
      @subscription = subscription
    end

    # Gets a value that indicates whether the object is unsubscribed.
    def unsubscribed?
      @subscription.nil?
    end

    # Unsubscribes the wrapped subscription on the provided scheduler.
    def unsubscribe
      @scheduler.schedule lambda {
        unless @subscription.nil?
          @subscription.dispose
          @subscription = nil
        end
      }
    end
  end
end