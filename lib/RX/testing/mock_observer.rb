# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/core/observer'
require 'rx/core/notification'
require 'rx/testing/recorded'

module RX

  class MockObserver
    include Observer

    attr_reader :messages

    def initalize(scheduler)
      raise 'scheduler cannot be nil' unless scheduler

      @scheduler = scheduler
      @messages = []
    end

    def on_next(value)
      messages.push(Recorded.new(@scheduler.clock, Notification.create_on_next(value)))
    end

    def on_error(error)
      messages.push(Recorded.new(@scheduler.clock, Notification.create_on_error(error)))
    end

    def on_completed
      messages.push(Recorded.new(@scheduler.clock, Notification.create_on_completed))
    end
  end
end
