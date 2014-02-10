# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/core/scheduled_observer'

module RX

  module Observer
    # Schedules the invocation of observer methods on the given scheduler.
    def notify_on(scheduler)
      ObserveOnObserver.new(scheduler, self, nil)
    end
  end

  class ObserveOnObserver < ScheduledObserver

    def initialize(scheduler, observer, cancel)
      @cancel = cancel

      super(scheduler, observer)      
    end

    def on_next_core(value)
      ensure_active
      super(value)
    end

    def on_error_core(error)
      ensure_active
      super(error)
    end

    def on_completed_core
      ensure_active
      super
    end

    def unsubscribe
      super

      cancel = nil
      Mutex.new.synchronize do
        cancel = @cancel
        @cancel = nil
      end

      canel.unsubscribe if cancel
    end
  end
end