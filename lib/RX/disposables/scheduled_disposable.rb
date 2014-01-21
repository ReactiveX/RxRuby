# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX
    # Represents a disposable resource whose disposal invocation will be scheduled on the specified scheduler
    class ScheduledDisposable

        attr_reader :scheduler, :disposable

        def initialize(scheduler, disposable)
            raise ArgumentException.new 'disposable cannot be nil' if disposable.nil?
            raise ArgumentException.new 'scheduler cannot be nil' if scheduler.nil?

            @scheduler = scheduler
            @disposable = disposable
        end

        # Gets a value that indicates whether the object is disposed.
        def disposed?
            @disposable.nil?
        end

        # Disposes the wrapped disposable on the provided scheduler.
        def dispose
            @scheduler.schedule lambda do
                unless @disposable.nil?
                    @disposable.dispose
                    @disposable = nil
                end
            end
        end
    end
end