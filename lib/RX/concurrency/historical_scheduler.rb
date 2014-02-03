# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/virtual_time_scheduler'
require 'rx/internal/priority_queue'

module RX

  # Provides a virtual time scheduler that uses Time for absolute time and Number for relative time.
  class HistoricalScheduler < VirtualTimeScheduler

    def initialize(clock = Time.new(1, 1, 1))
      @queue = PriorityQueue.new 1024
      super(clock)
    end

    # Schedules an action to be executed at due_time.
    def schedule_at_absolute_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      si = ScheduledItem.new self, state, due_time, lambda {|scheduler, state1|
        queue.delete si
        action.call(scheduler, state1)
      }

      queue.push si

      Subscription.create { si.cancel }
    end

    # Adds a relative time value to an absolute time value.
    def add(absolute, relative)
      absolute + relative
    end

    # Converts the absolute time value to a Time value.
    def to_time(absolute)
      absolute
    end

    # Converts the time span value to a relative time value.
    def to_relative(time_span)
      time_span
    end

    def get_next
      while queue.length > 0
        next_item = queue.Peek
        if next_item.cancelled?
          queue.shift
        else
          return next_item
        end
      end

      return nil
    end
  end
end