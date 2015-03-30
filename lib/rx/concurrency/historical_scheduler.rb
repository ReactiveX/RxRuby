# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/virtual_time_scheduler'
require 'rx/internal/priority_queue'

module RX

  # Provides a virtual time scheduler that uses Time for absolute time and Number for relative time.
  class HistoricalScheduler < VirtualTimeScheduler

    def initialize(clock = Time.at(0))
      super
      @clock = clock
    end
  end
end
