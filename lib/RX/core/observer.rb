# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX
    class ObserverConfiguration

        DEFAULT_ON_NEXT = lambda {|x| }
        DEFAULT_ON_ERROR = lambda {|error| raise error }
        DEFAULT_ON_COMPLETED = lambda { }

        attr_accessor(:on_next, :on_error, :on_completed)

        def initialize
            @on_next = DEFAULT_ON_NEXT
            @on_error = DEFAULT_ON_ERROR
            @on_completed = DEFAULT_ON_COMPLETED
        end
    end

    # Base class for implementations of the Observer
    class Observer

        def initialize(config)
            @config = config
            @stopped = false
        end

        def self.configure
            config = ObserverConfiguration.new
            yield config
            Observer.new config
        end

        # Unsubscribes from the current observer causing it to transition to the stopped state.
        def unsubscribe
            @stopped = true
        end
        
        # Notifies the observer of a new element in the sequence.
        def on_next(value)
            @config.on_next.call(value) unless @stopped
        end
        
        # Notifies the observer that an exception has occurred.
        def on_error(error)
            raise 'Error cannot be nil' unless error
            unless @stopped
                @stopped = true
                @config.on_error.call(error)
            end
        end
        
        # Notifies the observer of the end of the sequence.
        def on_completed
            unless @stopped
                @stopped = true
                @config.on_completed.call
            end
        end
    end
end
