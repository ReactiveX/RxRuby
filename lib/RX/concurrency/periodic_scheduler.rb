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

  end
end