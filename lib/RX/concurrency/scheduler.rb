# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX
	class Scheduler

		# Schedules an action to be executed.
		def schedule(&action)
			self.schedule(action, RX::Scheduler.invoke)
		end

		# Schedules an action to be executed after the specified relative due time.
		def schedule_relative(due_time, action)
			self.schedule_relative_with_state(due_time, action, RX::Scheduler.invoke)
		end

		# Schedules an action to be executed at the specified absolute due time.
		def schedule_absolute(due_time, action)
			self.schedule_absolute_with_state(due_time, action, RX::Scheduler.invoke)
		end

		def self.invoke(scheduler, action)
			action.call()
			RX::Scheduler.empty
		end

		# Normalizes the specified TimeSpan value to a positive value.
		def self.normalize(time_span)
			time_span < 0 ? 0 : time_span
		end

	end
end