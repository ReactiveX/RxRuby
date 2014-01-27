# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX
    class SingleAssignmentSubscription

        def initialize
            @gate = Mutex.new() 
            @current = nil
            @unsubscribed = false
            @set = false
        end

        def unsubscribed?
            @gate.synchronize do
                return @unsubscribed
            end
        end

        def subscription
            @current
        end

        def subscription=(new_subscription)
            raise Exception.new("Subscription already set") if @set

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