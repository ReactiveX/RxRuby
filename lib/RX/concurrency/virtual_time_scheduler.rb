# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/scheduler'
require 'rx/internal/default_comparer'
require 'rx/internal/priority_queue'
require 'rx/subscriptions/subscription'

module RX

  # Base class for virtual time schedulers using a priority queue for scheduled items.
  class VirtualTimeScheduler

    include Scheduler

    attr_reader :clock

    def initialize(initial_clock, comparer = DefaultComparer)
      @clock = initial_clock
      @comparer = comparer
      @queue = PriorityQueue.new 1024
    end

    # Schedules an action to be executed at dueTime.
    def schedule_at_abosolute(state, due_time, action)
      raise 'action cannot be nil' unless action

      si = nil
      run = lambda {|scheduler, state1|
        queue.delete si
        action.call(scheduler, state1)
      }

      si = ScheduledItem.new(self, state, run, due_time, @comparer)
      queue.push si

      Subscription.create { si.cancel }
    end

    # Gets the next scheduled item to be executed
    def get_next
      while queue.length > 0
        next_item = queue.peek
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
