# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'singleton'
require 'thread'
require 'rx/concurrency/local_scheduler'
require 'rx/concurrency/periodic_scheduler'
require 'rx/subscriptions/subscription'
require 'rx/subscriptions/single_assignment_subscription'
require 'rx/subscriptions/composite_subscription'

module RX

  # Represents an object that schedules units of work on the platform's default scheduler.
  class DefaultScheduler < RX::LocalScheduler

    include Singleton
    include RX::PeriodicScheduler

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
        d.subscription = action.call self, state unless d.unsubscribed?
      end

      CompositeSubscription.new [d, Subscription.create { t.exit }]         
    end

    # Schedules a periodic piece of work
    def schedule_periodic_with_state(state, due_time, action)
        raise 'action cannot be nil' unless action
        raise 'due_time cannot be less than zero' if due_time < 0

        state1 = state
        gate = Mutex.new

        PeriodicTimer.new due_time do 
          gate.synchronize do
            state1 = action.call state1
          end
        end
    end

    private

    # Internal timer
    class PeriodicTimer
      def initialize(seconds, &action)
        @seconds = seconds
        @unsubscribed = false
        @gate = Mutex.new

        self.run_loop &action
      end

      def unsubscribe
        @gate.synchronize do
          @unsubscribed = true unless @unsubscribed
        end
      end

      def time_block
        start_time = Time.new
        yield
        Time.new - start_time
      end

      def run_loop
        Thread.new do
          should_run = true

          while should_run
            sleep( @seconds - time_block { yield } ) 
            @gate.synchronize do
              should_run = !@unsubscribed
            end                    
          end
        end
      end
    end
  end
end