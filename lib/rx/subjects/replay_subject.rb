# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/concurrency/current_thread_scheduler'
require 'rx/core/observer'
require 'rx/core/observable'
require 'rx/core/time_interval'

module Rx

  # Represents an object that is both an observable sequence as well as an observer.
  # Each notification is broadcasted to all subscribed and future observers, subject to buffer trimming policies.
  class ReplaySubject

    include Observer
    include Observable

    INFINITE_BUFFER_SIZE = Float::MAX.to_i

    def initialize(buffer_size = INFINITE_BUFFER_SIZE, window_size = INFINITE_BUFFER_SIZE, scheduler = CurrentThreadScheduler.instance)
      @buffer_size = buffer_size
      @window_size = window_size
      @scheduler = scheduler
      @queue = []
      @observers = []
      @stopped = false
      @error = nil
    end

    # Indicates whether the subject has observers subscribed to it.
    # @return [B]
    def has_observers?
      observers = @observers
      observers && observers.length > 0
    end

  end

end