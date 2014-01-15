# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX
    class SingleAssignmentDisposable

        def initialize
            @gate = Mutex.new
            @current = nil
            @disposed = false
        end

        def disposed?
            gate.synchronize do
                return @disposed
            end
        end

        def disposable
            @current
        end

        def disposable=(new_disposable)
            raise Exception.new("Disposable already set") unless @current.nil?

            shouldDispose = false
            old = nil
            @gate.synchronize do
                shouldDispose = @disposed
                unless shouldDispose
                    old = current
                    @current = new_disposable
                end
            end

            old.dispose unless old.nil?
            new_disposable.dispose if shouldDispose && !foo.nil?            
        end      

        def dispose
            old = nil
            @gate.synchronize do
                unless @disposed
                    @disposed = true
                    old = @current
                    @current = nil
                end
            end

            old.dispose unless old.nil?
        end

    end
end