# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx_ruby/subscriptions/subscription'
require 'rx_ruby/subscriptions/composite_subscription'
require 'rx_ruby/testing/test_subscription'

module RxRuby

  class ColdObservable

    attr_reader :messages, :subscriptions

    def initialize(scheduler, *args)
      raise 'scheduler cannot be nil' unless scheduler

      @scheduler = scheduler
      @messages = args
      @subscriptions = []
    end

    def subscribe(observer)
      raise 'observer cannot be nil' unless observer

      subscriptions.push(TestSubscription.new @scheduler.clock)
      index = subscriptions.length - 1

      d = CompositeSubscription.new

      messages.each do |message|
        notification = message.value

        d.push(@scheduler.schedule_at_relative_with_state(nil, message.time, lambda {|scheduler1, state1|
          notification.accept observer
          Subscription.empty
        }))
      end

      return Subscription.create do
        subscriptions[index] = TestSubscription.new(subscriptions[index].subscribe, @scheduler.clock)
        d.unsubscribe
      end
    end

  end
end