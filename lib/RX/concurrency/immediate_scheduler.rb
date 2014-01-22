# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/concurrency/local_scheduler'
require 'rx/disposables/single_assignment_disposable'

module RX

    class AsyncLockScheduler < RX::LocalScheduler

        def initialize
            @gate = nil
        end

        def schedule_with_state(state, action)
            m = RX::SingleAssignmentDisposable.new

            @gate = Mutex.new if @gate.nil?

            @gate.synchronize do 
                m.disposable = action.call(self, state) unless m.disposed?
            end

            m
        end

        def schedule_relative_with_state(state, due_time, action) 
            return self.schedule_with_state state, action if due_time <= 0

            m = RX::SingleAssignmentDisposable.new

            timer = Time.new

            @gate = Mutex.new if @gate.nil?

            @gate.synchronize do
                sleep_time = Time.new - timer
                sleep(sleep_time) if sleep_time > 0
                m.disposable = action.call(self, state) unless m.disposed?
            end

            m
        end

    end

    # Represents an object that schedules units of work to run immediately on the current thread.
    class ImmediateScheduler < RX::LocalScheduler

        include Singleton

        # Schedules an action to be executed.
        def schedule_with_state(state, action)
            raise Exception.new 'action cannot be nil' if action.nil?

            action.call AsyncLockScheduler.new, state
        end

        def schedule_relative_with_state(state, due_time, action)
            raise Exception.new 'action cannot be nil' if action.nil?

            dt = RX::Scheduler.normalize(due_time)
            sleep(dt) if dt > 0
            action.call AsyncLockScheduler.new, state
        end
    end

end
