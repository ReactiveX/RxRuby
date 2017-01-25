# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/concurrency/default_scheduler'
require 'rx/subscriptions/subscription'
require 'rx/subscriptions/composite_subscription'
require 'rx/subscriptions/ref_count_subscription'
require 'rx/subscriptions/serial_subscription'
require 'rx/subscriptions/single_assignment_subscription'
require 'rx/core/observer'
require 'rx/core/observable'
require 'rx/subjects/subject'


module Rx

  # Time based operations
  module Observable

    # Projects each element of an observable sequence into consecutive non-overlapping buffers which are produced
    # based on timing information.
    def buffer_with_time(time_span, time_shift = time_span, scheduler = DefaultScheduler.instance)
      raise ArgumentError.new 'time_span must be greater than zero' if time_span <= 0
      raise ArgumentError.new 'time_span must be greater than zero' if time_shift <= 0
      window_with_time(time_span, time_shift, scheduler).flat_map(&:to_a)
    end

    # Projects each element of an observable sequence into consecutive non-overlapping windows which are produced
    # based on timing information.
    def window_with_time(time_span, time_shift = time_span, scheduler = DefaultScheduler.instance)
      raise ArgumentError.new 'time_span must be greater than zero' if time_span <= 0
      raise ArgumentError.new 'time_span must be greater than zero' if time_shift <= 0

      AnonymousObservable.new do |observer|
        total_time = 0
        next_shift = time_shift
        next_span = time_span

        gate = Mutex.new
        q = []

        timer_d = SerialSubscription.new
        group_subscription = CompositeSubscription.new [timer_d]
        ref_count_subscription = RefCountSubscription.new(group_subscription)

        create_timer = lambda {
          m = SingleAssignmentSubscription.new
          timer_d.subscription = m

          is_span = false
          is_shift = false
          if next_span == next_shift
            is_span = true
            is_shift = true
          elsif next_span < next_shift
            is_span = true
          else
            is_shift = true
          end

          new_total_time = is_span ? next_span : next_shift
          ts = new_total_time - total_time
          total_time = new_total_time

          if is_span
            next_span += time_shift
          end
          if is_shift
            next_shift += time_shift
          end

          m.subscription = scheduler.schedule_relative(ts, lambda {
            gate.synchronize do
              if is_shift
                s = Subject.new
                q.push s
                observer.on_next(s.add_ref(ref_count_subscription))
              end
              if is_span
                s = q.shift
                s.on_completed
              end
              create_timer.call
            end
          })
        }

        q.push(Subject.new)
        observer.on_next(q[0].add_ref(ref_count_subscription))
        create_timer.call

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            gate.synchronize do
              q.each {|s| s.on_next x}
            end
          end

          o.on_error do |err|
            gate.synchronize do
              q.each {|s| s.on_error err}
              observer.on_error err
            end
          end

          o.on_completed do
            gate.synchronize do
              q.each {|s| s.on_completed}
              observer.on_completed
            end
          end
        end

        group_subscription.push subscribe(new_obs)

        ref_count_subscription
      end
    end
  end
end
