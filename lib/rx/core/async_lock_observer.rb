# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/async_lock'
require 'rx/core/observer'

module Rx

  module Observer

    class << self
      # Synchronizes access to the observer such that its callback methods cannot be called concurrently, using the specified asynchronous lock to protect against concurrent and reentrant access.
      # This overload is useful when coordinating multiple observers that access shared state by synchronizing on a common asynchronous lock.
      def prevent_reentrancy(observer, gate = AsyncLock.new)
        AsyncLockObserver.new(observer, gate)
      end
    end
  end

  class AsyncLockObserver < Rx::ObserverBase

    def on_next_core(value)
      @gate.wait { @observer.on_next value }
    end

    def on_error_core(error)
      @gate.wait { @observer.on_error error }
    end

    def on_completed_core
      @gate.wait { @observer.on_completed }
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
