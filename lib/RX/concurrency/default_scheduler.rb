# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/concurrency/local_scheduler'
require 'rx/disposables/disposable'
require 'rx/disposables/single_assignment_disposable'
require 'rx/disposables/composite_disposable'

module RX

    # Represents an object that schedules units of work on the platform's default scheduler.
    class DefaultScheduler < RX::LocalScheduler

        include Singleton

        # Schedules an action to be executed.
        def schedule_with_state(state, action)
             raise Exception.new 'action cannot be nil' if action.nil?

             d = SingleAssignmentDisposable.new

             t = Thread.new do
                d.disposable = action.call self, state unless d.disposed?
             end

             cancel = RX::Disposable.create lambda { t.exit }

             CompositeDisposable.new [d, cancel]
        end

        # Schedules an action to be executed after dueTime
        def schedule_relative_with_state(state, due_time, action)
            raise Exception.new 'action cannot be nil' if action.nil?

            dt = RX::Scheduler.normalize due_time
            return self.schedule_with_state state, action if dt == 0

            d = SingleAssignmentDisposable.new

            t = Thread.new do
                sleep dt
                d.disposable = action.call self, state unless d.disposed?
            end

            cancel = RX::Disposable.create lambda { t.exit }

            CompositeDisposable.new [d, cancel]         
        end
    end

end