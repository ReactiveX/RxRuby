# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

  # Provides periodic scheduling capabilities
  module PeriodicScheduler

    # Schedules a periodic piece of work by dynamically discovering the scheduler's capabilities.
    def schedule_periodic(period, action)
      raise 'action cannot be nil' unless action
      raise 'period cannot be less than zero' if period < 0

      self.schedule_periodic_with_state(action, period, lambda {|a|
        a.call
        return a
      })
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

        self.run_loop(&action)
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

          elapsed = 0
          while should_run
            sleep @seconds - elapsed
            elapsed = time_block { yield }
            @gate.synchronize do
              should_run = !@unsubscribed
            end                    
          end
        end
      end
    end
  end
end
