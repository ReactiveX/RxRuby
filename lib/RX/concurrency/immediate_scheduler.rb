# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/concurrency/local_scheduler'
require 'rx/disposables/single_assignment_disposable'

module RX

	class ImmediateScheduler < RX::LocalScheduler

		@@instance = ImmediateScheduler.new

		def self.instance
			@@instance
		end

		def schedule_with_state(state, action)
			action.call(AsyncLockScheduler.new(), state)
		end

		def schedule_relative_with_state(state, due_time, &action)
			dt = RX::Scheduler.normalize(due_time)
			sleep(dt) if dt > 0
			action.call(AsyncLockScheduler.new(), state)
		end


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

				return m
			end

			def schedule_relative_with_state(state, due_time, action) 
				return self.schedule_with_state if due_time <= 0

				m = new RX::SingleAssignmentDisposable.new

				timer = Time.new

				@gate = Mutex.new if @gate.nil?

				@gate.synchronize do
					sleep_time = Time.new() - timer
					sleep(sleep_time) if sleep_time > 0
					m.disposable = action.call(self, state) unless m.disposed?
				end

				return m
			end

		end

	end

end