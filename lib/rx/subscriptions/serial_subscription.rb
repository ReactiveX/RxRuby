# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX

  # Represents a subscription resource whose underlying subscription resource can be replaced by another subscription resource, causing automatic disposal of the previous underlying subscription resource.
  class SerialSubscription

    def initialize
      @gate = Mutex.new
      @current = nil
      @unsubscribed = false
    end

    # Gets a value that indicates whether the object is unsubscribed.
    def unsubscribed?
      @gate.synchronize do
        return @unsubscribed
      end
    end

    # Gets the underlying subscription.
    def subscription
      @current
    end

    # Sets the underlying subscription.
    def subscription=(new_subscription)
      should_unsubscribe = false
      old = nil
      @gate.synchronize do
        should_unsubscribe = @unsubscribed
        unless should_unsubscribe
          old = @current
          @current = new_subscription
        end
      end

      old.unsubscribe if old
      new_subscription.unsubscribe if should_unsubscribe && !new_subscription.nil?
    end

    # Unsubscribes the current underlying subscription and all future subscriptions.
    def unsubscribe
      old = nil
      @gate.synchronize do
        unless @unsubscribed
          @unsubscribed = true
          old = @current
          @current = nil
        end
      end

      old.unsubscribe if old
    end

  end
end