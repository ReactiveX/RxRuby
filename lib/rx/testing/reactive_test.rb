# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/core/notification'
require 'rx/testing/recorded'

module RX

  # Module to write unit tests for applications and libraries built using Reactive Extensions.
  module ReactiveTest

    # Default virtual time used for creation of observable sequences in ReactiveTest-based unit tests.
    CREATED = 100

    # Default virtual time used to subscribe to observable sequences in ReactiveTest-based unit tests.
    SUBSCRIBED = 200

    # Default virtual time used to dispose subscriptions in ReactiveTest-based unit tests.
    DISPOSED = 1000

    # Factory method for an on_next notification record at a given time with a given value.
    def on_next(ticks, value)
      Recorded.new(ticks, Notification.create_on_next(value))
    end

    # Factory method for writing an assert that checks for an on_next notification record at a given time, using the specified predicate to check the value.
    def on_next_predicate(ticks, &block)
      n = OnNextPredicate.new &block
      Recorded.new(ticks, n)
    end

    # Factory method for an on_error notification record at a given time with a given error.
    def on_error(ticks, error)
      Recorded.new(ticks, Notification.create_on_error(error))
    end

    # Factory method for writing an assert that checks for an on_error notification record at a given time, using the specified predicate to check the exception.
    def on_next_predicate(ticks, &block)
      n = OnErrorPredicate.new &block
      Recorded.new(ticks, n)
    end

    # Factory method for an OnCompleted notification record at a given time.
    def on_completed(ticks)
      Recorded.new(ticks, Notification.create_on_completed)
    end

  end
end
