# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/core/observer'
require 'rx/core/observable'
require 'rx/subscriptions/subscription'

module RX

  # Represents the result of an asynchronous operation.
  # Each notification is broadcasted to all subscribed observers.
  class AsyncSubject

    include Observable
    include Observer

    attr_reader :gate, :observers, :unsubscribed

    def initialize
      @observers = []
      @gate = Mutex.new
      @unsubscribed = false
      @stopped = false
      @error = nil
      @value = nil
      @has_value = false
    end

    # Indicates whether the subject has observers subscribed to it.
    def has_observers?
      observers && observers.length > 0
    end

    # Notifies all subscribed observers about the end of the sequence.
    def on_completed
      os = nil
      v = nil
      hv = false

      gate.synchronize do 
        self.check_unsubscribed

        unless @stopped
          os = @observers.clone
          observers = []
          @stopped = true
          v = @value
          hv = @has_value
        end 
      end

      if os
        if hv
          os.each do |o|
            o.on_next @value
            o.on_completed
          end
        else
          os.each {|o| o.on_completed }
        end
      end
    end

    # Notifies all subscribed observers with the error.
    def on_error(error)
      raise 'error cannot be nil' unless error

      os = nil
      gate.synchronize do
        self.check_unsubscribed

        unless @stopped
          os = observers.clone
          observers = []
          @stopped = true
          @error = error
        end         
      end

      os.each {|o| observer.on_error error } if os
    end

    # Notifies all subscribed observers with the value.
    def on_next(value) 
      gate.synchronize do 
        self.check_unsubscribed
        unless @stopped
          @value = value
          @has_value = true
        end
      end
    
    end

    # Subscribes an observer to the subject.
    def subscribe(observer)
      raise 'observer cannot be nil' unless observer

      err = nil
      v = nil
      hv = false

      gate.synchronize do
        self.check_unsubscribed

        if !@stopped
          observers.push(observer)
          return InnerSubscription.new(self, observer)
        end

        err = @error
        v = @value
        hv = @has_value
      end

      if err
        observer.on_next err
      elsif hv
        observer.on_next @value
        observer.on_completed
      else
        observer.on_completed
      end

      Subscription.empty
    end

    # Unsubscribe all observers and release resources.
    def unsubscribe
      gate.synchronize do
        unsubscribed = true
        observers = nil
        @error = nil
        @value = nil
      end
    end    

    class InnerSubscription
      def initialize(subject, observer)
        @subject = subject
        @observer = observer
      end

      def unsubscribe
        if @observer
          @subject.gate.synchronize do
            if !@subject.unsubscribed && @observer
              @subject.observers.delete @observer
              @observer = nil
            end
          end
        end
      end
    end

    private 

    def check_unsubscribed
      raise 'Subject unsubscribed' if unsubscribed
    end
  end
end  