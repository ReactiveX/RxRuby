# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'monitor'
require 'rx/subscriptions/serial_subscription'
require 'rx/core/observer'

module RX

  class ScheduledObserver < ObserverBase

    def initialize(scheduler, observer)
      @scheduler = scheduler
      @observer = observer
      @gate = Monitor.new
      @queue = []
      @subscriber = SerialSubscription.new
      @acquired = false
      @faulted = false

      config = ObserverConfiguration.new
      config.on_next &method(:on_next_core)
      config.on_error &method(:on_error_core)
      config.on_completed &method(:on_completed_core)

      super(config)      
    end

    def on_next_core(value)
      @gate.synchronize { @queue.push(lambda { @observer.on_next value }) }
    end

    def on_error_core(error)
       @gate.synchronize { @queue.push(lambda { @observer.on_error error }) }
    end

    def on_completed_core
       @gate.synchronize { @queue.push(lambda { @observer.on_completed }) }
    end

    def ensure_active(n=0)
      owner = false

      @gate.synchronize do
        if !@faulted && @queue.length > 0
          owner = !@acquired
          @acquired = true
        end
      end

      @subscriber.subscription = @scheduler.schedule_recursive_with_state(nil, method(:run)) if owner
    end

    def run(state, recurse)
      work = nil
      @gate.synchronize do
        if @queue.length > 0
          work = @queue.shift
        else
          @acquired = false
          return
        end
      end

      begin
        work.call
      rescue => e
        @queue = []
        @fauled = true

        raise e
      end

      recurse.call state
    end

    def unsubscribe
      super
      @subscriber.unsubscribe
    end

  end

end