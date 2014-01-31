# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX
  
  # Represents a group of subscription resources that are unsubscribed together.
  class CompositeSubscription
  
    include Enumerable

    attr_reader :length

    def initialize(subscriptions = [])
      @subscriptions = subscriptions
      @length = subscriptions.length
      @unsubscribed = false
      @gate = Mutex.new
    end

    # Gets a value that indicates whether the object is unsubscribed.
    def unsubscribed?
      @unsubscribed
    end

    def each(&block)
      @subscriptions.each(&block)
    end

    # Unsubscribes all subscriptions in the group and removes them from the group.
    def unsubscribe
      currentSubscriptions = nil

      @gate.synchronize do
        unless @unsubscribed
          @unsubscribed = true
          currentSubscriptions = @subscriptions
          @subscriptions = []
          @length = 0
        end
      end

      currentSubscriptions.each {|subscription| subscription.unsubscribe} if currentSubscriptions
    end

    # Adds a subscription to the CompositeSubscription or unsubscribes the subscription if the CompositeSubscription is unsubscribed.
    def push(subscription)
      should_unsubscribe = false
    
      @gate.synchronize do
        should_unsubscribe = @unsubscribed
  
        unless @unsubscribed
          @subscriptions.push(subscription)
          @length += 1
        end
      end
    
      subscription.unsubscribe if should_unsubscribe

      return self
    end
    alias_method :>>, :push
    
    # Removes and unsubscribes all subscriptions from the CompositeSubscription, but does not dispose the CompositeSubscription.
    def clear
      currentSubscriptions = nil
    
      @gate.synchronize do
        currentSubscriptions = @subscriptions
        @subscriptions = []
        @length = 0
      end
      currentSubscriptions.each {|subscription| subscription.unsubscribe}
    end
    
    # Removes and unsubscribes the first occurrence of a subscription from the CompositeSubscription.
    def delete(subscription)
      should_unsubscribe = nil
    
      @gate.synchronize do
        should_unsubscribe = @subscriptions.delete(subscription)
        @length -= 1 if should_unsubscribe
      end
    
      subscription.unsubscribe if should_unsubscribe

      should_unsubscribe
    end
  end
end
