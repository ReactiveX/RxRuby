require 'thread'
require 'rx/disposables/empty_disposable'

module Rx
    class MultipleAssignmentDisposable

        @@empty_disposable = EmptyDisposable.new

        def initialize 
            @gate = Mutex.new
            @current = nil
            @disposed = false
        end

        def disposed?
            @gate.synchronize do
                return @disposed
            end
        end

        def disposable
            @gate.synchronize do
                return @disposed ? @@empty_disposable : @current
            end
        end

        def disposable=(new_disposable)
            should_dispose = false
            @gate.synchronize do
                should_dispose = @current.nil?
                @current = new_disposable if should_dispose
            end
        end

        def dispose
            old = nil
            @gate.synchronize do
                unless @disposed
                    old = @current
                    @curret = nil
                end
            end

            old.dispose unless old.nil?
        end
    end
end