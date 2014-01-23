# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'singleton'
require 'thread'
require 'rx/concurrency/local_scheduler'
require 'rx/concurrency/scheduled_item'
require 'rx/disposables/disposable'
require 'rx/disposables/single_assignment_disposable'
require 'rx/disposables/composite_disposable'

module RX

    # Represents an object that schedules units of work on the platform's default scheduler.
    class CurrentThreadScheduler < RX::LocalScheduler

    	include Singleton

        @@thread_local_queue = nil

        # Gets a value that indicates whether the caller must call a Schedule method.
        def schedule_required?
            @@thread_local_queue.nil?
        end

        def schedule_relative_with_state(state, due_time, action)
            raise Exception.new 'action cannot be nil' if action.nil?

            dt = self.now + RX::Scheduler.normalize(due_time)
            si = ScheduledItem.new 
        end

    	private

        def self.queue
            @@thread_local_queue
        end

        def self.queue=(new_queue)
            @@thread_local_queue = new_queue
        end

    	class Trampoline

    		def self.run(queue)
    			while queue.length > 0
    				item = queue.shift
    				unless item.cancelled?
						wait = item.due_time - RX::Scheduler.now
						sleep(wait) if wait > 0
                        item.invoke unless item.cancelled?
    				end
    			end
    		end

    	end

    end

end