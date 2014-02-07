# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/current_thread_scheduler'
require 'rx/concurrency/immediate_scheduler'
require 'rx/subscriptions/composite_subscription'
require 'rx/subscriptions/subscription'

module RX

  module Observable

    # Creation Operators

    # Creates an observable sequence from a specified subscribe method implementation.
    def self.create(&subscribe)
      AnonymousObservable.new do |observer|
        a = subscribe.call observer
        a = RX::Subscription.empty unless a
        a
      end
    end

    # Returns an observable sequence that invokes the specified factory function whenever a new observer subscribes.
    def self.defer
      AnonymousObservable.new do |observer|
        result = nil
        begin
          result = yield
        rescue => err
          self.class.raise err
        end

        result.subscribe observer
      end
    end

    # Returns an empty observable sequence, using the specified scheduler to send out the single OnCompleted message.
    def self.empty(scheduler = ImmediateScheduler.instance)
      AnonymousObservable.new do |observer|
        scheduler.schedule lambda {
          observer.on_completed
        }
      end
    end

    # Generates an observable sequence by running a state-driven loop producing the sequence's elements.
    def self.generate(initial_state, condition, result_selector, iterate, scheduler = CurrentThreadScheduler.instance)
      AnonymousObservable.new do |observer|
        state = initial_state
        first = true
        
        scheduler.schedule_recursive lambda{|this|
          hasResult = false
          result = nil
          begin
            if first
              first = false
            else
              state = iterate.call state
            end
            hasResult = condition.call state
            if hasResult
              result = result_selector.call state
            end
          rescue => err
            observer.on_error err
            return
          end
          if hasResult
            observer.on_next result
            this.call
          else
            observer.on_completed
          end
        }
      end
    end    

    # Returns a non-terminating observable sequence, which can be used to denote an infinite duration (e.g. when using reactive joins).
    def self.never
      AnonymousObservable.new do |observer|

      end
    end

    # Returns an observable sequence that contains a single element.
    def self.just(value, scheduler = ImmediateScheduler.instance)
      AnonymousObservable.new do |observer|
        scheduler.schedule lambda {
          observer.on_next value
          observer.on_completed
        }
      end
    end

    # Converts an array to an observable sequence, using an optional scheduler to enumerate the array.
    def self.of_array(array, scheduler = CurrentThreadScheduler.instance)
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

    # Returns an observable sequence that terminates with an exception.
    def self.raise(error, scheduler = ImmediateScheduler.instance)
      AnonymousObservable.new do |observer|
        scheduler.schedule lambda {
          observer.on_error error
        }
      end
    end

    # Generates an observable sequence of integral numbers within a specified range.
    def self.range(start, count, scheduler = CurrentThreadScheduler.instance)
      AnonymousObservable.new do |observer|
        scheduler.schedule_with_state 0, lambda {|i, this|
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
    def self.repeat_infinitely(value, scheduler = CurrentThreadScheduler.instance)
      self.class.just(value, scheduler).repeat
    end

    # Generates an observable sequence that repeats the given element the specified number of times.
    def self.repeat(value, count, scheduler = CurrentThreadScheduler.instance)
      self.class.just(value, scheduler).repeat(count)
    end

    # Constructs an observable sequence that depends on a resource object, whose lifetime is tied to the resulting observable sequence's lifetime.
    def self.using(resource_factory, observable_factory)
      AnonymousObservable.new do |observer|
        source = nil
        subscription = Subscription.empty
        begin
          resource = resource_factory.call
          subscription = resource unless resource.nil?
          source = observable_factory.call resource
        rescue => e
          return CompositeSubscription.new [self.class.raise(e).subscribe(observer), subscription]
        end

        CompositeSubscription.new [source.subscribe(observer), subscription]
      end
    end
  
  end
end