# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/core/notification'

module RX

  # Configuration class for storing Observer actions
  class ObserverConfiguration

    DEFAULT_ON_NEXT = lambda {|x| }
    DEFAULT_ON_ERROR = lambda {|error| raise error }
    DEFAULT_ON_COMPLETED = lambda { }

    attr_reader :on_next_action, :on_error_action, :on_completed_action

    def initialize
      @on_next_action = DEFAULT_ON_NEXT
      @on_error_action = DEFAULT_ON_ERROR
      @on_completed_action = DEFAULT_ON_COMPLETED
    end

    def on_next(&on_next_action)
      @on_next_action = on_next_action
    end

    def on_error(&on_error_action)
      @on_error_action = on_error_action
    end

    def on_completed(&on_completed_action)
      @on_completed_action = on_completed_action
    end    
  end

  # Module for all Observers
  module Observer

    # Hides the identity of an observer.
    def as_observer
      self.class.configure do |o|
        o.on_next      {|x| self.on_next x }
        o.on_error     {|err| self.on_error err }
        o.on_completed { self.on_completed }
      end      
    end

    # Creates a notification callback from an observer.
    def to_notifier
      lambda {|n| n.accept self}
    end

    # Creates an observer from a notification callback.
    def to_observer
      raise 'Block required' unless block_given?

      self.class.configure do |o|
        o.on_next      {|x| yield Notification.create_on_next(x) }
        o.on_error     {|err| yield Notification.create_on_error(err) }
        o.on_completed { yield Notification.create_on_completed }
      end
    end

    class << self

      # Configures a new instance of an Observer
      def configure
        config = ObserverConfiguration.new
        yield config if block_given?
        ObserverBase.new config
      end

    end

  end

  class ObserverBase
    include Observer

    def initialize(config)
      @config = config
      @stopped = false
    end

    # Unsubscribes from the current observer causing it to transition to the stopped state.
    def unsubscribe
      @stopped = true
    end
    
    # Notifies the observer of a new element in the sequence.
    def on_next(value)
      @config.on_next_action.call value unless @stopped
    end
    
    # Notifies the observer that an exception has occurred.
    def on_error(error)
      raise 'Error cannot be nil' unless error
      unless @stopped
        @stopped = true
        @config.on_error_action.call error
      end
    end
    
    # Notifies the observer of the end of the sequence.
    def on_completed
      unless @stopped
        @stopped = true
        @config.on_completed_action.call
      end
    end

    def fail(error) 
      unless @stopped
        @stopped = true
        @config.on_error_action.call error
        return true
      end
      return false
    end    
  end
end
