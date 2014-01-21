# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX
	class Scheduler

		# Schedules an action to be executed.
		def schedule(action)
			raise ArgumentError.new 'action cannot be nil' if action.nil?
			self.schedule_with_state(action, lambda { |sched, fn| RX::Scheduler.invoke(sched, fn) })
		end

		# Schedules an action to be executed after the specified relative due time.
		def schedule_relative(due_time, action)
			raise ArgumentError.new 'action cannot be nil' if action.nil?
			self.schedule_relative_with_state(action, due_time, lambda { |sched, fn| RX::Scheduler.invoke(sched, fn) })
		end

		# Schedules an action to be executed at the specified absolute due time.
		def schedule_absolute(due_time, action)
			raise ArgumentError.new 'action cannot be nil' if action.nil?
			self.schedule_absolute_with_state(action, due_time, lambda { |sched, fn| RX::Scheduler.invoke(sched, fn) })
		end

		# Schedules an action to be executed recursively.
		def schedule_recursive(action)
			raise ArgumentError.new 'action cannot be nil' if action.nil?
			self.schedule_recursive_with_state(action, lambda {|_action, _self| _action(lambda { _self(_action) }) })
		end

		# Schedules an action to be executed recursively.
		def schedule_recursive_with_state(state, action)
			raise ArgumentError.new 'action cannot be nil' if action.nil?
			self.schedule_with_state({ :state => state, :action => action}, RX::Scheduler.invoke_recursive)
		end

		# Normalizes the specified TimeSpan value to a positive value.
		def self.normalize(time_span)
			time_span < 0 ? 0 : time_span
		end

		private

		def self.invoke(scheduler, action)
			action.call()
			RX::Disposable.empty
		end

		def self.invoke_recursive(scheduler, pair)
			group = RX::CompositeDisposable.new
			gate = Mutex.new
			state = pair[:state]
			action = pair[:action]

			recursive_action = lambda do |state1|
				action.call(state, lambda do |state2|  
					is_added = false
					is_done = false
					d = scheduler.schedule_with_state(state2, lambda do |scheduler1, state3| 
						@gate.synchronize do
							if is_added
								group.delete(d)
							else
								is_done = true
							end
						end

						recursive_action.call(state3)
						return RX::Disposable.empty
					end)

					@gate.synchronize do
						unless is_done
							group.push(d)
							is_added = true
						end
					end
				end)
			end

			recursive_action(state)
			return group
		end

	end
end