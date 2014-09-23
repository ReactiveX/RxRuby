# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/subscriptions/subscription'

module RX

  # Represents a subscription resource that only disposes its underlying subscription resource when all dependent subscription objects have been unsubscribed.
  class RefCountSubscription

    def initialize(subscription)
      raise ArgumentError.new 'Subscription cannot be nil' unless subscription

      @subscription = subscription
      @primary_unsubscribed = false
      @gate = Mutex.new
      @count = 0
    end

    # Gets a value that indicates whether the object is disposed.
    def unsubscribed?
      @subscription.nil?
    end

    # Returns a dependent subscription that when disposed decreases the refcount on the underlying subscription.
    def subscription
      @gate.synchronize do 
        if @subscription
          @count += 1
          return InnerSubscription.new self
        else
          return Subscription.empty
        end
      end
    end

    # Unsubscribes the underlying subscription only when all dependent subscriptions have been unsubscribed.
    def unsubscribe
      subscription = nil
      @gate.synchronize do
        if @subscription
          unless @primary_unsubscribed
            @primary_unsubscribed = true

            if @count == 0
              subscription = @subscription
              @subscription = nil
            end
          end
        end
      end

      subscription.unsubscribe if subscription
    end

    def release
      subscription = nil
      @gate.synchronize do
        if @subscription
          @count =- 1

          if @primary_unsubscribed && @count == 0
            subscription = @subscription
            @subscription = nil
          end
        end
      end

      subscription.unsubscribe if subscription
    end

    class InnerSubscription
      def initialize(parent)
        @parent = parent
      end

      def unsubscribe
        parent = nil
        Mutex.new.synchronize do
          parent = @parent
          @parent = nil
        end
        parent.release if parent
      end
    end

  end
end
