# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'monitor'
require 'rx/concurrency/async_lock'
require 'rx/subscriptions/subscription'
require 'rx/subscriptions/composite_subscription'
require 'rx/subscriptions/ref_count_subscription'
require 'rx/subscriptions/single_assignment_subscription'
require 'rx/core/observer'
require 'rx/core/observable'

module RX

  module Observable

    class AmbObserver
      attr_accessor(:observer)

      def method_missing(m, *args, &block)
        @observer.method(m).call(*args)
      end
    end

    # Propagates the observable sequence that reacts first.
    def amb(second)
      AnonymousObservable.new do |observer|
        left_subscription = SingleAssignmentSubscription.new
        right_subscription = SingleAssignmentSubscription.new
        choice = :neither

        gate = Monitor.new

        left = AmbObserver.new
        right = AmbObserver.new

        handle_left = lambda do |&action|
          if choice == :neither
            choice = :left
            right_subscription.unsubscribe
            left.observer = observer
          end

          action.call if choice == :left
        end

        handle_right = lambda do |&action|
          if choice == :neither
            choice = :right
            left_subscription.unsubscribe
            right.observer = observer
          end

          action.call if choice == :right
        end

        left_obs = Observer.configure do |o|
          o.on_next {|x| handle_left.call { observer.on_next x } }
          o.on_error {|err| handle_left.call { observer.on_error err } }
          o.on_completed { handle_left.call { observer.on_completed } }
        end

        right_obs = Observer.configure do |o|
          o.on_next {|x| handle_right.call { observer.on_next x } }
          o.on_error {|err| handle_right.call { observer.on_error err } }
          o.on_completed { handle_right.call { observer.on_completed } }
        end        

        left.observer = Observer.allow_reentrancy(left_obs, gate)
        right.observer = Observer.allow_reentrancy(right_obs, gate)

        left_subscription.subscription = self.subscribe left
        right_subscription.subscription = second.subscribe right

        CompositeSubscription.new [left_subscription, right_subscription]
      end
    end

    # Continues an observable sequence that is terminated by an exception of the specified type with the observable sequence produced by the handler or
    # continues an observable sequence that is terminated by an exception with the next observable sequence.
    def rescue_error(other = nil, &action)
      return Observable.rescue_error(other) if other && !block_given?
      raise ArgumentError.new 'Invalid arguments' if other.nil && !block_given?

      AnonymousObservable.new do |observer|
        subscription = SerialSubscription.new

        d1 = SingleAssignmentSubscription.new
        subscription.subscription = d1

        new_obs = Observer.configure do |o|
          o.on_next &observer.method(:on_next)
          
          o.on_error do |err|
            result = nil
            begin
              result = action.call(err)
            rescue => e
              observer.on_error(e)
              return
            end

            d = SingleAssignmentSubscription.new
            subscription.subscription = d
            d.subscription = result.subscribe observer
          end

          o.on_completed &observer.method(:on_completed)          
        end

        d1.subscription = subscribe new_obs
        subscription
      end
    end  

    def combineLatest(other, &result_selector)
      has_left = false
      has_right = false

      left = nil
      right = nil

      left_done = false
      right_done = false

      # TODO: Finish Impl
    end

    class << self

      # Propagates the observable sequence that reacts first.
      def amb(*args)
        args.reduce(Observable.never) {|previous, current| previous.amb current }
      end

      # Continues an observable sequence that is terminated by an exception with the next observable sequence.
      def rescue_error(*args)
        AnonymousObservable.new do |observer|
          gate = AsyncLock.new
          disposed = false
          e = args.length == 1 && args[0].is_a?(Enumerator) ? args[0] : args.to_enum
          subscription = SerialSubscription.new
          last_error = nil

          cancelable = CurrentThreadScheduler.instance.schedule_recursive do |this|
            gate.wait do
              current = nil
              has_next = false

              if !disposed
                begin
                  current = e.next
                  has_next = true
                rescue StopIteration => se
                  
                end
              else
                return
              end

              unless has_next
                if last_error
                  observer.on_error last_error
                else
                  observer.on_completed
                end
                return
              end

              new_obs = Observer.configure do |o|
                o.on_next &observer.method(:on_next)

                o.on_error do |err|
                  last_error = err
                  this.call
                end

                o.on_completed &observer.method(:on_completed)    
              end

              d = SingleAssignmentSubscription.new
              subscription.subscription = d
              d.subscription = current.subscribe new_obs
            end
          end

          CompositeSubscription.new [subscription, cancelable, Subscription.create { gate.wait { disposed = true } }]
        end
      end

    end
  end
end
