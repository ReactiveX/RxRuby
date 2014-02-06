# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX

  # Module for scheduling actions
  module Scheduler

    # Gets the current time according to the local machine's system clock.
    def self.now
      Time.now
    end

    # Schedules an action to be executed.
    def schedule(action)
      raise 'action cannot be nil' unless action
      self.schedule_with_state(action, method(:invoke))
    end

    # Schedules an action to be executed after the specified relative due time.
    def schedule_relative(due_time, action)
      raise 'action cannot be nil' unless action
      self.schedule_relative_with_state(action, due_time, method(:invoke))
    end

    # Schedules an action to be executed at the specified absolute due time.
    def schedule_absolute(due_time, action)
      raise 'action cannot be nil' unless action
      self.schedule_absolute_with_state(action, due_time, method(:invoke))
    end

    # Schedules an action to be executed recursively.
    def schedule_recursive(action)
      raise 'action cannot be nil' unless action
      self.schedule_recursive_with_state(action, lambda {|_action, _self| _action.call(lambda { _self.call(_action) }) })
    end

    # Schedules an action to be executed recursively.
    def schedule_recursive_with_state(state, action)
      raise 'action cannot be nil' unless action
      self.schedule_with_state({ :state => state, :action => action}, method(:invoke_recursive))
    end

    # Schedules an action to be executed recursively after a specified relative due time.
    def schedule_recursive_relative(due_time, action)
      raise 'action cannot be nil' unless action
      self.schedule_recursive_relative_with_state(action, due_time, lambda {|_action, _self| _action.call(lambda {|dt| _self.call(_action, dt) }) })
    end

    # Schedules an action to be executed recursively after a specified relative due time.
    def schedule_recursive_relative_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action
      self.schedule_relative_with_state(
        { :state => state, :action => action}, 
        due_time,
        lambda { |sched, pair| invoke_recursive_time(sched, pair, 'schedule_relative_with_state') }
      )
    end

    # Schedules an action to be executed recursively after a specified absolute due time.
    def schedule_recursive_absolute(due_time, action)
      raise 'action cannot be nil' unless action
      self.schedule_recursive_absolute_with_state(action, due_time, lambda {|_action, _self| _action.call(lambda {|dt| _self.call(_action, dt) }) })
    end

    # Schedules an action to be executed recursively after a specified absolute due time.
    def schedule_recursive_absolute_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action
      self.schedule_absolute_with_state(
        { :state => state, :action => action}, 
        due_time,
        lambda { |sched, pair| invoke_recursive_time(sched, pair, 'schedule_absolute_with_state') }
      )
    end

    # Normalizes the specified TimeSpan value to a positive value.
    def self.normalize(time_span)
      time_span < 0 ? 0 : time_span
    end

    private

    def invoke(scheduler, action)
      action.call()
      Subscription.empty
    end

    def invoke_recursive(scheduler, pair)
      group = CompositeSubscription.new
      gate = Mutex.new
      state = pair[:state]
      action = pair[:action]

      recursive_action = lambda {|state1|
        action.call(state1, lambda {|state2|  
          is_added = false
          is_done = false
          d = scheduler.schedule_with_state(state2, lambda {|scheduler1, state3| 
            gate.synchronize do
              if is_added
                group.delete(d)
              else
                is_done = true
              end
            end

            recursive_action.call(state3)
            Subscription.empty
          })

          gate.synchronize do
            unless is_done
              group.push(d)
              is_added = true
            end
          end
        })
      }

      recursive_action.call(state)
      group
    end

    def invoke_recursive_time(scheduler, pair, method)
      group = CompositeSubscription.new
      gate = Mutex.new
      state = pair[:state]
      action = pair[:action]

      recursive_action = lambda { |state1|
        action.call(state1, lambda { |state2, due_time1|
          is_added = false
          is_done = false

          d = scheduler.send(method, state2, due_time1, lambda { |scheduler1, state3|
            gate.synchronize do
              if is_added
                group.delete(d)
              else
                is_done = true
              end
            end
            recursive_action.call(state3)
            Subscription.empty
          })

          gate.synchronize do
            unless is_done
              group.push(d)
              is_added = true
            end
          end
        })
      }

      recursive_action.call(state)
      group            
    end
  end
end