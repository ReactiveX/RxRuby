# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/core/observer'
require 'rx/core/observable'
require 'rx/subscriptions/subscription'

module RX

  # Represents an object that is both an observable sequence as well as an observer.
  # Each notification is broadcasted to all subscribed observers.
  class Subject

    include Observable
    include Observer

    def initialize
      @observers = []
      @gate = Mutex.new
      @disposed = false
      @stopped = false
      @error = nil
    end

    # Indicates whether the subject has observers subscribed to it.
    def has_observers?
      @observers && @observers.length > 0
    end

    # Notifies all subscribed observers about the end of the sequence.
    def on_completed
      os = nil
      @gate.synchronize do 
        self.check_disposed

        unless @stopped
          os = @observers.clone
          @observers = []
          @stopped = true
        end 
      end

      os.each {|o| observer.on_completed } if os
    end

    # Notifies all subscribed observers with the error.
    def on_error(error)
      raise 'error cannot be nil' unless error

      os = nil
      @gate.synchronize do
        self.check_disposed

        unless @stopped
          os = @observers.clone
          @observers = []
          @stopped = true
          @error = error
        end         
      end

      os.each {|o| observer.on_error error } if os
    end

    # Notifies all subscribed observers with the value.
    def on_next(value) 
      os = nil
      @gate.synchronize do 
        self.check_disposed
        os = @observers.clone unless @stopped
      end

      os.each {|o| observer.on_next value } if os      
    end

    # Subscribes an observer to the subject.
    def subscribe(observer)
      raise 'observer cannot be nil' unless observer

      @gate.synchronize do
        self.check_disposed

        if !@stopped
          @observers.push(observer)
          return InnerSubscription.new(self, observer)
        elsif @exception
          observer.on_error @exception
          return Subscription.empty
        else
          observer.on_completed
          return Subscription.empty
        end
      end
    end

    # Unsubscribe all observers and release resources.
    def unsubscribe
      @gate.synchronize do
        @disposed = true
        @observers = nil
      end
    end

    class InnerSubscription
      def initialize(subject, observer)
        @subject = subject
        @observer = observer
      end

      def unsubscribe
        if @observer
          @subject.unsubscribe_observer(@observer)
          @subject = nil
          @observer = nil
        end
      end
    end

    private 

    def unsubscribe_observer(observer)
      @gate.synchronize do
        @observers.delete(observer) if @observers
      end
    end

    def check_disposed
      raise 'Subject disposed' if @disposed
    end
  end
end  