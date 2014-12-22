# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/current_thread_scheduler'
require 'rx/concurrency/immediate_scheduler'
require 'rx/subscriptions/composite_subscription'
require 'rx/subscriptions/subscription'

module RX

  module Observable

    # Creation Operators

    class << self

      # Creates an observable sequence from a specified subscribe method implementation.
      def create(&subscribe)
        AnonymousObservable.new do |observer|
          subscription = subscribe.call(observer)
          case subscription
          when Subscription
            subscription
          when Proc
            Subscription.create(&subscription)
          else
            Subscription.empty
          end
        end
      end

      # Returns an observable sequence that invokes the specified factory function whenever a new observer subscribes.
      def defer
        AnonymousObservable.new do |observer|
          result = nil
          e = nil
          begin
            result = yield
          rescue => err
            e = Observable.raise_error(err).subscribe(observer)
          end

          e || result.subscribe(observer)
        end
      end

      # Returns an empty observable sequence, using the specified scheduler to send out the single OnCompleted message.
      def empty(scheduler = ImmediateScheduler.instance)
        AnonymousObservable.new do |observer|
          scheduler.schedule lambda {
            observer.on_completed
          }
        end
      end

      # Generates an observable sequence by running a state-driven loop producing the sequence's elements.
      def generate(initial_state, condition, result_selector, iterate, scheduler = CurrentThreadScheduler.instance)
        AnonymousObservable.new do |observer|
          state = initial_state
          first = true
          
          scheduler.schedule_recursive lambda{|this|
            has_result = false
            result = nil
            begin

              if first
                first = false
              else
                state = iterate.call(state)
              end

              has_result = condition.call(state)

              if has_result
                result = result_selector.call state
              end
            rescue => err
              observer.on_error err
              return
            end
            if has_result
              observer.on_next result
              this.call
            else
              observer.on_completed
            end
          }
        end
      end    

      # Returns a non-terminating observable sequence, which can be used to denote an infinite duration (e.g. when using reactive joins).
      def never
        AnonymousObservable.new do |_|

        end
      end

      # Returns an observable sequence that contains a single element.
      def just(value, scheduler = ImmediateScheduler.instance)
        AnonymousObservable.new do |observer|
          scheduler.schedule lambda {
            observer.on_next value
            observer.on_completed
          }
        end
      end

      # Converts an array to an observable sequence, using an optional scheduler to enumerate the array.
      def of_array(array, scheduler = CurrentThreadScheduler.instance)
        AnonymousObservable.new do |observer|
          count = 0
          scheduler.schedule_recursive lambda {|this|
            if count < array.length
              observer.on_next array[count]
              count += 1
              this.call
            else
              observer.on_completed
            end
          }
        end
      end

      # Converts an Enumerable to an observable sequence, using an optional scheduler to enumerate the array.
      def of_enumerable(enumerable, scheduler = CurrentThreadScheduler.instance)
        Observer.of_enumerator(enumerable.to_enum, scheduler)
      end

      # Converts an Enumerator to an observable sequence, using an optional scheduler to enumerate the array.
      def of_enumerator(enum, scheduler = CurrentThreadScheduler.instance)
        AnonymousObservable.new do |observer|
          scheduler.schedule_recursive lambda {|this|
            has_value = false
            value = nil

            begin
              value = enum.next
              has_value = true
            rescue StopIteration => _
              observer.on_completed
            rescue => e
              observer.on_error e
            end

            if has_value
              observer.on_next value
              this.call
            end
          }
        end
      end

      # Returns an observable sequence that terminates with an exception.
      def raise_error(error, scheduler = ImmediateScheduler.instance)
        AnonymousObservable.new do |observer|
          scheduler.schedule lambda {
            observer.on_error error
          }
        end
      end

      # Generates an observable sequence of integral numbers within a specified range.
      def range(start, count, scheduler = CurrentThreadScheduler.instance)
        AnonymousObservable.new do |observer|
          scheduler.schedule_recursive_with_state 0, lambda {|i, this|
            if i < count
              observer.on_next (start + i)
              this.call(i + 1)
            else
              observer.on_completed
            end
          }
        end
      end

      # Generates an observable sequence that repeats the given element infinitely.
      def repeat_infinitely(value, scheduler = CurrentThreadScheduler.instance)
        Observable.just(value, scheduler).repeat_infinitely
      end

      # Generates an observable sequence that repeats the given element the specified number of times.
      def repeat(value, count, scheduler = CurrentThreadScheduler.instance)
        Observable.just(value, scheduler).repeat(count)
      end

      # Constructs an observable sequence that depends on a resource object, whose lifetime is tied to the resulting observable sequence's lifetime.
      def using(resource_factory, observable_factory)
        AnonymousObservable.new do |observer|
          source = nil
          subscription = Subscription.empty
          begin
            resource = resource_factory.call
            subscription = resource unless resource.nil?
            source = observable_factory.call resource
          rescue => e
            return CompositeSubscription.new [self.class.raise_error(e).subscribe(observer), subscription]
          end

          CompositeSubscription.new [source.subscribe(observer), subscription]
        end
      end
  
      def from_array(array, scheduler = CurrentThreadScheduler.instance)
        AnonymousObservable.new do |observer|
          scheduler.schedule_recursive_with_state 0, lambda {|i, this|
            if i < array.size
              observer.on_next array[i]
              this.call(i + 1)
            else
              observer.on_completed
            end
          }
        end
      end

    end

  end
end
