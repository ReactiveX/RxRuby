# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/subscriptions/single_assignment_subscription'

module RX
  
  # Represents a scheduled work item based on the materialization of an scheduler.schedule method call.
  class ScheduledItem

    include Comparable

    attr_reader :due_time

    def initialize(scheduler, state, due_time, &action)
      @scheduler = scheduler
      @state = state
      @action = action
      @due_time = due_time
      @subscription = SingleAssignmentSubscription.new
    end

    # Gets whether the work item has received a cancellation request.
    def cancelled?
      @subscription.unsubscribed?
    end

    # Invokes the work item.
    def invoke
      @subscription.subscription = @action.call @scheduler, @state unless @subscription.unsubscribed?
    end

    def <=>(other)
      return @due_time <=> other.due_time
    end

    # Cancels the work item by disposing the resource returned by invoke_core as soon as possible.
    def cancel
      @subscription.unsubscribe
    end

  end
end