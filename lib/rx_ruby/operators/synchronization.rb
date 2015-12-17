# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'monitor'
require 'rx_ruby/subscriptions/single_assignment_subscription'
require 'rx_ruby/subscriptions/serial_subscription'
require 'rx_ruby/subscriptions/scheduled_subscription'
require 'rx_ruby/core/observer'
require 'rx_ruby/core/observable'
require 'rx_ruby/core/observe_on_observer'

module RxRuby
  module Observable

    # Wraps the source sequence in order to run its subscription and unsubscribe logic on the specified scheduler.
    def subscribe_on(scheduler)
      raise ArgumentError.new 'Scheduler cannot be nil' unless scheduler

      AnonymousObservable.new do |observer|
        m = SingleAssignmentSubscription.new
        d = SerialSubscription.new
        d.subscription = m

        m.subscription = scheduler.schedule lambda {
          d.subscription = ScheduledSubscription.new scheduler, (subscribe observer)
        }

        d
      end
    end
  
    # Wraps the source sequence in order to run its observer callbacks on the specified scheduler.
    def observe_on(scheduler)
      raise ArgumentError.new 'Scheduler cannot be nil' unless scheduler

      AnonymousObservable.new do |observer|
        subscribe(ObserveOnObserver.new scheduler, observer)
      end
    end

    # Wraps the source sequence in order to ensure observer callbacks are synchronized using the specified gate object.
    def synchronize(gate = Monitor.new)
      AnonymousObservable.new do |observer|
        subscribe(Observer.allow_reentrancy observer, gate)
      end
    end
  end
end
