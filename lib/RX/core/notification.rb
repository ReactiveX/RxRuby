# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/immediate_scheduler'
require 'rx/core/observable'

module RX

  # Represents a notification to an observer.
  module Notification

    class << self

      # Creates an object that represents an on_next notification to an observer.
      def create_on_next(value)
        OnNextNotification.new value
      end

      # Creates an object that represents an on_error notification to an observer.
      def create_on_error(error)
        OnErrorNotification.new error
      end

      # Creates an object that represents an on_completed notification to an observer.
      def create_on_completed
        OnCompletedNotification.new
      end

    end

    # Determines whether this is an on_next notification.
    def on_next?
      @kind == :on_next
    end

    # Determines whether this is an on_error notification.
    def on_error?
      @kind == :on_error
    end

    # Determines whether this is an on_completed notification.
    def on_completed?
      @kind == :on_completed
    end

    # Determines whether this notification has a value.
    def has_value?
      false
    end

    # Returns an observable sequence with a single notification.
    def to_observable(scheduler=ImmediateScheduler)
      AnonymousObservable.new do |observer|
        scheduler.schedule lamdba {
          self.accept observer
          observer.on_completed if self.on_next?
        }
      end
    end

  end

  # Represents an on_next notification to an observer.
  class OnNextNotification
    include Notification

    attr_reader :value

    def initialize(value)
      @value = value
      @kind = :on_next
    end

    # Determines whether this notification has a value.
    def has_value?
      true
    end

    def ==(other)
      o.class == self.class && other.on_next? && value == other.value
    end
    alias_method :eql?, :==

    def to_s
      "on_next#{value}"
    end

    # Invokes the observer's method corresponding to the notification.
    def accept(observer)
      observer.on_next value
    end

  end

  # Represents an on_error notification to an observer.
  class OnErrorNotification
    include Notification

    attr_reader :error

    def initialize(error)
      @error = error
      @kind = :on_error
    end

    def ==(other)
      o.class == self.class && other.on_error? && error == other.error
    end
    alias_method :eql?, :==

    def to_s
      "on_error#{error}"
    end

    # Invokes the observer's method corresponding to the notification.
    def accept(observer)
      observer.on_error error
    end

  end

  # Represents an on_completed notification to an observer.
  class OnCompletedNotification
    include Notification

    def initialize
      @kind = :on_completed
    end

    def ==(other)
      o.class == self.class && other.on_completed?
    end
    alias_method :eql?, :==

    def to_s
      "on_completed"
    end

    # Invokes the observer's method corresponding to the notification.
    def accept(observer)
      observer.on_completed
    end    

  end

end