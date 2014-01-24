# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX
    class EmptyDisposable
        def dispose

        end
    end

    class AnonymousDisposable
        def initialize(&disposable_action)

            @disposable_action = disposable_action
            @gate = Mutex.new
            @disposed = false
        end
    
        def dispose
            should_dispose = false
            @gate.synchronize do
                should_dispose = !@disposed
            end
  
            @disposable_action.call if should_dispose
        end
    end

    # Provides a set of class methods for creating Disposables.
    class Disposable
       
        @@empty_disposable = RX::EmptyDisposable.new

        # Creates a disposable object that invokes the specified action when disposed.
        def self.create(&disposable_action)
            AnonymousDisposable.new &disposable_action
        end

        # Gets the disposable that does nothing when disposed.
        def self.empty
            @@empty_disposable
        end
    end
end
