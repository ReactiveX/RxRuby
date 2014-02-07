# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/scheduler'
require 'rx/internal/priority_queue'
require 'rx/subscriptions/subscription'

module RX

  # Base class for virtual time schedulers using a priority queue for scheduled items.
  class VirtualTimeScheduler

    include Scheduler

    attr_reader :clock

    def initialize(initial_clock)
      @clock = initial_clock
      @queue = PriorityQueue.new 1024
      @enabled = false
    end

    # Gets the scheduler's notion of current time.
    def now
      self.to_time clock
    end

    # Gets whether the scheduler is enabled to run work.
    def enabled?
      @enabled
    end

    # Starts the virtual time scheduler.
    def start
      unless @enabled
        @enabled = true

        begin
          next_item = self.get_next

          unless next_item.nil?
            @clock = next_item.due_time if next_item.due_time > @clock
            next_item.invoke
          else
            @enabled = false
          end

        end while @enabled
      end
    end  

    # Stops the virtual time scheduler.
    def stop
      @enabled = false
    end

    # Schedules an action to be executed.
    def schedule_with_state(state, action)
      raise 'action cannot be nil' unless action
      self.schedule_at_absolute_with_state(state, @clock, action)
    end

    # Schedules an action to be executed after due_time.
    def schedule_relative_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      self.schedule_at_relative_with_state(state, self.to_relative(due_time), action)
    end

    # Schedules an action to be executed at due_time.
    def schedule_absolute_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      self.schedule_at_relative_with_state(state, self.to_relative(due_time - self.now), action)
    end

    # Schedules an action to be executed at due_time.
    def schedule_at_relative(due_time, action)
      raise 'action cannot be nil' unless action

      self.schedule_at_relative_with_state(action, due_time, method(:invoke))
    end

    # Schedules an action to be executed at due_time.
    def schedule_at_relative_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      run_at = self.add(@clock, due_time)

      self.schedule_at_absolute_with_state(state, run_at, action)
    end

    # Schedules an action to be executed at due_time.
    def schedule_at_absolute(due_time, action)
      raise 'action cannot be nil' unless action

      self.schedule_at_absolute_with_state(action, due_time, method(:invoke))      
    end

    # Schedules an action to be executed at due_time.
    def schedule_at_absolute_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      si = nil
      run = lambda {|scheduler, state1|
        @queue.delete si
        action.call(scheduler, state1)
      }

      si = ScheduledItem.new(self, state, due_time, &run)
      @queue.push si

      Subscription.create { si.cancel }
    end

    # Advances the scheduler's clock to the specified time, running all work till that point.
    def advance_to(time)
      due_to_clock = time<=>@clock
      raise 'Time is out of range' if due_to_clock < 0 

      return if due_to_clock == 0

      unless @enabled
        @enabled = true

        begin
          next_item = self.get_next
          if !next_item.nil? && next_item.due_time <= time
            @clock = next_item.due_time if next_item.due_time > @clock
            next_item.invoke
          else
            @enabled = false
          end

        end while @enabled

        @clock = time
      else
        raise 'Cannot advance while running'
      end

    end

    # Advances the scheduler's clock by the specified relative time, running all work scheduled for that timespan.
    def advance_by(time)
      dt = self.add(@clock, time)

      due_to_clock = dt<=>@clock
      raise 'Time is out of range' if due_to_clock < 0

      return if due_to_clock == 0
      raise 'Cannot advance while running' if @enabled

      self.advance_to dt
    end  

    # Advances the scheduler's clock by the specified relative time.
    def sleep(time)
      dt = self.add(@clock, time)

      due_to_clock = dt<=>@clock
      raise 'Time is out of range' if due_to_clock < 0

      @clock = dt
    end

    # Gets the next scheduled item to be executed
    def get_next
      while @queue.length > 0
        next_item = @queue.peek
        if next_item.cancelled?
          @queue.shift
        else
          return next_item
        end
      end

      return nil
    end

    def invoke(scheduler, action)
      action.call
      Subscription.empty
    end
  end
end
