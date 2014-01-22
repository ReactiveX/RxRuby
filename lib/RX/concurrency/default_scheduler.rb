# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'singleton'
require 'thread'
require 'rx/concurrency/local_scheduler'
require 'rx/concurrency/periodic_scheduler'
require 'rx/disposables/disposable'
require 'rx/disposables/single_assignment_disposable'
require 'rx/disposables/composite_disposable'

module RX

    # Represents an object that schedules units of work on the platform's default scheduler.
    class DefaultScheduler < RX::LocalScheduler

        include Singleton
        include RX::PeriodicScheduler

        # Schedules an action to be executed.
        def schedule_with_state(state, action)
             raise Exception.new 'action cannot be nil' if action.nil?

             d = SingleAssignmentDisposable.new

             t = Thread.new do
                d.disposable = action.call self, state unless d.disposed?
             end

             cancel = Disposable.create lambda { t.exit }

             CompositeDisposable.new [d, cancel]
        end

        # Schedules an action to be executed after dueTime
        def schedule_relative_with_state(state, due_time, action)
            raise Exception.new 'action cannot be nil' if action.nil?

            dt = Scheduler.normalize due_time
            return self.schedule_with_state state, action if dt == 0

            d = SingleAssignmentDisposable.new

            t = Thread.new do
                sleep dt
                d.disposable = action.call self, state unless d.disposed?
            end

            cancel = Disposable.create lambda { t.exit }

            CompositeDisposable.new [d, cancel]         
        end

        # Schedules a periodic piece of work
        def schedule_periodic_with_state(state, due_time, action)
            raise Exception.new 'action cannot be nil' if action.nil?
            raise Exception.new 'due_time cannot be less than zero' if due_time < 0

            state1 = state
            gate = Mutex.new
            return PeriodicTimer.new due_time do 
                gate.synchronize do
                    state1 = action.call state1
                end
            end
        end

        private

        # Internal timer
        class PeriodicTimer
            def initialize(seconds, &action)
                @seconds = seconds
                @disposed = false
                @gate = Mutex.new

                self.run_loop &action
            end

            def dispose
                @gate.synchronize do
                    @disposed = true unless @disposed
                end
            end

            def time_block
                start_time = Time.new
                yield
                Time.new - start_time
            end

            def run_loop
                Thread.new do
                    should_run = true

                    while should_run
                        sleep( @seconds - time_block { yield } ) 
                        @gate.synchronize do
                            should_run = !@disposed
                        end                    
                    end
                end
            end
        end

    end
end