# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

  # Represents a value that changes over time.
  # Observers can subscribe to the subject to receive the last (or initial) value and all subsequent notifications.
  class BehaviorSubject

    include Observable
    include Observer

    attr_reader :gate, :observers, :unsubscribed

    def initialize(value)
      @value = value
      @observers = []
      @gate = Mutex.new
      @unsubscribed = false
      @stopped = false
      @error = nil
    end

    # Indicates whether the subject has observers subscribed to it.
    def has_observers?
      observers && observers.length > 0
    end

    # Gets the current value or throws an exception.
    def value
      gate.synchronize do 
        self.check_unsubscribed
        raise @error if @error
        @value
      end
    end

    # Notifies all subscribed observers about the end of the sequence.
    def on_completed
      os = nil
      @gate.synchronize do 
        self.check_unsubscribed

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
        self.check_unsubscribed

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
        self.check_unsubscribed
        @value = value
        os = @observers.clone unless @stopped
      end

      os.each {|o| observer.on_next value } if os      
    end

    # Subscribes an observer to the subject.
    def subscribe(observer)
      raise 'observer cannot be nil' unless observer

      gate.synchronize do
        self.check_unsubscribed

        unless @stopped
          observers.push(observer)
          observer.on_next(@value)
          return InnerSubscription.new(self, observer)
        end

        err = @error
      end

      if err
        observer.on_next err
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