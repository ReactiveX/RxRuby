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

        def unsubscribed?
            @unsubscribed
        end

        def each(&block)
            @subscriptions.each(&block)
        end
    
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
        
        def clear
            currentSubscriptions = nil
          
            @gate.synchronize do
                currentSubscriptions = @subscriptions
                @subscriptions = []
                @length = 0
            end
            currentSubscriptions.each {|subscription| subscription.unsubscribe}
        end
        
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
