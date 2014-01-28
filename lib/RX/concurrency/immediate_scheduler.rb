# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'singleton'
require 'thread'
require 'rx/concurrency/local_scheduler'
require 'rx/subscriptions/single_assignment_subscription'

module RX

  # Represents an object that schedules units of work to run immediately on the current thread.
  class ImmediateScheduler < LocalScheduler

    include Singleton

    # Schedules an action to be executed.
    def schedule_with_state(state, action)
      raise 'action cannot be nil' unless action
      action.call AsyncLockScheduler.new, state
    end

    def schedule_relative_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      dt = RX::Scheduler.normalize due_time
      sleep dt if dt > 0
      action.call AsyncLockScheduler.new, state
    end

    private

    class AsyncLockScheduler < LocalScheduler

      def initialize
          @gate = nil
      end

      def schedule_with_state(state, action)
        m = SingleAssignmentSubscription.new

        @gate = Mutex.new if @gate.nil?

        @gate.synchronize do 
          m.subscription = action.call self, state unless m.unsubscribed?
        end

        m
      end

      def schedule_relative_with_state(state, due_time, action) 
        return self.schedule_with_state state, action if due_time <= 0

        m = SingleAssignmentSubscription.new

        timer = Time.new

        @gate = Mutex.new if @gate.nil?

        @gate.synchronize do
          sleep_time = Time.new - timer
          sleep sleep_time if sleep_time > 0
          m.subscription = action.call self, state unless m.unsubscribed?
        end

        m
      end
    end
  end
end
