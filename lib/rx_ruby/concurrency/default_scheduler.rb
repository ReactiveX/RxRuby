# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'singleton'
require 'thread'
require 'rx_ruby/concurrency/local_scheduler'
require 'rx_ruby/concurrency/periodic_scheduler'
require 'rx_ruby/subscriptions/subscription'
require 'rx_ruby/subscriptions/single_assignment_subscription'
require 'rx_ruby/subscriptions/composite_subscription'

module RxRuby

  # Represents an object that schedules units of work on the platform's default scheduler.
  class DefaultScheduler < RxRuby::LocalScheduler

    include Singleton
    include RxRuby::PeriodicScheduler

    # Schedules an action to be executed.
    def schedule_with_state(state, action)
      raise 'action cannot be nil' unless action

      d = SingleAssignmentSubscription.new

      t = Thread.new do
        d.subscription = action.call self, state unless d.unsubscribed?
      end

      CompositeSubscription.new [d, Subscription.create { t.exit }]
    end

    # Schedules an action to be executed after dueTime
    def schedule_relative_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      dt = Scheduler.normalize due_time
      return self.schedule_with_state state, action if dt == 0

      d = SingleAssignmentSubscription.new

      t = Thread.new do
        sleep dt
        Thread.new {
          d.subscription = action.call self, state unless d.unsubscribed?
        }
      end

      CompositeSubscription.new [d, Subscription.create { t.exit }]         
    end
  end
end
