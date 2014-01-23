# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX
	# Represents a scheduled work item based on the materialization of an scheduler.schedule method call.
	class ScheduledItem

		attr_reader :due_time

		def initialize(scheduler, state, due_time, action, comparer = RX::DefaultComparer.new)
			@scheduler = scheduler
			@state = state
			@action = action
			@due_time = due_time
			@comparer = comparer
			@disposable = RX::SingleAssignmentDisposable.new
		end

		# Gets whether the work item has received a cancellation request.
		def cancelled?
			@disposed.disposed?
		end

		# Invokes the work item.
		def invoke
			@disposable.dispoasble = @action.call @scheduler, @state unless @disposable.disposed?
		end

		# Compares the work item with another work item based on absolute time values.
		def compare_to(other)
			return 1 if other.nil?
			return @comparer.compare @due_time, other.due_time
		end

		# Cancels the work item by disposing the resource returned by invoke_core as soon as possible.
		def cancel
			@disposable.dispose
		end

	end
end