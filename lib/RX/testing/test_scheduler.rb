# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/virtual_time_scheduler'
require 'rx/subscriptions/subscription'
require 'rx/testing/cold_observable'
require 'rx/testing/hot_observable'
require 'rx/testing/mock_observer'
require 'rx/testing/reactive_test'

module RX

  # Virtual time scheduler used for testing applications and libraries built using Reactive Extensions.
  class TestScheduler < VirtualTimeScheduler

    # Schedules an action to be executed at due_time.
    def schedule_at_relative_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      due_time = clock + 1 if due_time <= clock

      super(state, run_at, action)
    end

    # Adds a relative virtual time to an absolute virtual time value.
    def add(absolute, relative)
      absolute + relative
    end

    # Converts the absolute time value to a Time value.
    def to_time(absolute)
      Time.at absolute
    end

    # Converts the time span value to a relative time value.
    def to_relative(time_span)
      time_span
    end    

    # Starts the test scheduler and uses the specified virtual times to invoke the factory function, subscribe to the resulting sequence, and unsubscribe the subscription.
    def create(options = {}, &action)
      o = {
        :created    => ReactiveTest::CREATED,
        :subscribed => ReactiveTest::SUBSCRIBED,
        :disposed   => ReactiveTest::DISPOSED
      }.merge(options)

      source = nil
      subscription = nil
      observer = self.create_observer

      self.schedule_at_absolute_with_state(nil, o[:created], lambda {|scheduler, state|
        source = acton.call
        Subscription.empty
      })

      self.schedule_at_absolute_with_state(nil, o[:subscribed], lambda {|scheduler, state|
        subscription = source.subscribe observer
        Subscription.empty
      })

       self.schedule_at_absolute_with_state(nil, o[:disposed], lambda {|scheduler, state|
        subscription.unsubscribe
        Subscription.empty
      })
      
      observer           
    end

    # Creates a hot observable using the specified timestamped notification messages.
    def create_hot_observable(*args)
      HotObservable.new(self, *args)
    end

    # Creates a cold observable using the specified timestamped notification messages.
    def create_cold_observable(*args)
      ColdObservable.new(self, *args)
    end

    # Creates an observer that records received notification messages and timestamps those.
    def create_observer
      MockObserver.new self
    end

  end
end