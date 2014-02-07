# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'singleton'

module RX
  class EmptySubscription

    include Singleton

    def unsubscribe

    end
  end

  class AnonymousSubscription

    def initialize(&unsubscribe_action)
      @unsubscribe_action = unsubscribe_action
      @gate = Mutex.new
      @unsubscribed = false
    end

    def unsubscribe
      should_unsubscribe = false
      @gate.synchronize do
        should_unsubscribe = !@unsubscribed
      end

      @unsubscribe_action.call if should_unsubscribe
    end
  end

  # Provides a set of class methods for creating Disposables.
  class Subscription

    # Creates a subscription object that invokes the specified action when unsubscribed.
    def self.create(&unsubscribe_action)
      AnonymousSubscription.new &unsubscribe_action
    end

    # Gets the subscription that does nothing when unsubscribed.
    def self.empty
      EmptySubscription.instance
    end
  end
end
