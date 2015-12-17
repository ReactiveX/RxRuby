# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'monitor'
require 'rx_ruby/core/observer'

module RxRuby

  module Observer

    class << self
      # Synchronizes access to the observer such that its callback methods cannot be called concurrently by multiple threads, using the specified gate object for use by a Monitor based lock.
      # This overload is useful when coordinating multiple observers that access shared state by synchronizing on a common gate object if given.
      # Notice reentrant observer callbacks on the same thread are still possible.
      def allow_reentrancy(observer, gate = Monitor.new)
        SynchronizedObserver.new(observer, gate)
      end
    end
  end

  class SynchronizedObserver < RxRuby::ObserverBase

    def on_next_core(value)
      @gate.synchronize { @observer.on_next value }
    end

    def on_error_core(error)
      @gate.synchronize { @observer.on_error error }
    end

    def on_completed_core
      @gate.synchronize { @observer.on_completed }
    end

    def initialize(observer, gate)
      @observer = observer
      @gate = gate

      config = ObserverConfiguration.new
      config.on_next(&method(:on_next_core))
      config.on_error(&method(:on_error_core))
      config.on_completed(&method(:on_completed_core))

      super(config)
    end

  end
end
