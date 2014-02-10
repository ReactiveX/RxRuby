# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/core/observer'

module RX

  module Observer
    # Checks access to the observer for grammar violations. This includes checking for multiple on_error or on_completed calls, as well as reentrancy in any of the observer methods.
    # If a violation is detected, an error is thrown from the offending observer method call.
    def checked
      CheckedObserver.new(self)
    end
  end

  class CheckedObserver
    include Observer

    IDLE = 0
    BUSY = 1
    DONE = 2

    def initialize(observer)
      @observer = observer
      @state = IDLE
    end

    def on_next(value)
      check_access
      begin
        @observer.on_next value
      ensure
        Mutex.new.synchronize { @state = IDLE }
      end
    end

    def on_error(error)
      check_access
      begin
        @observer.on_error error
      ensure
        Mutex.new.synchronize { @state = DONE }
      end
    end

    def on_completed
      check_access
      begin
        @observer.on_completed
      ensure
        Mutex.new.synchronize { @state = DONE }
      end
    end

    private

    def check_access
      Mutex.new.synchronize do 
        old = @state
        @state = BUSY if @state == IDLE
        case old
        when BUSY
          raise 'Re-entrancy detected'
        when DONE
          raise 'Observer terminated'
        end
      end
    end
  end
end