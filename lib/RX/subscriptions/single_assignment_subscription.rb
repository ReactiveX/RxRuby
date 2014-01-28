# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX

  # Represents a subscription resource which only allows a single assignment of its underlying subscription resource.
  # If an underlying subscription resource has already been set, future attempts to set the underlying subscription resource will throw an error
  class SingleAssignmentSubscription

    def initialize
      @gate = Mutex.new() 
      @current = nil
      @unsubscribed = false
      @set = false
    end

    # Gets a value that indicates whether the object is unsubscribed.
    def unsubscribed?
      @gate.synchronize do
        return @unsubscribed
      end
    end

    # Gets the underlying subscription. After unsubscribing, the result of getting this property is undefined.
    def subscription
      @current
    end

    # Sets the underlying disposable. If this has already been set, then an error is raised.
    def subscription=(new_subscription)
      raise 'Subscription already set' if @set

      @set = true
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

    # Unsubscribes the underlying subscription
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