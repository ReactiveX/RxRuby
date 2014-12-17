# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'monitor'
require 'rx/concurrency/async_lock'
require 'rx/subscriptions/subscription'
require 'rx/subscriptions/composite_subscription'
require 'rx/subscriptions/ref_count_subscription'
require 'rx/subscriptions/single_assignment_subscription'
require 'rx/core/observer'
require 'rx/core/observable'
require 'rx/operators/creation'

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
      raise ArgumentError.new 'Invalid arguments' if other.nil? && !block_given?

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

    # Merges two observable sequences into one observable sequence by using the selector function whenever one of the observable sequences produces an element.
    def combine_latest(other, &result_selector)
      AnonymousObservable.new do |observer|
        has_left = false
        has_right = false

        left = nil
        right = nil

        left_done = false
        right_done = false

        left_subscription = SingleAssignmentSubscription.new
        right_subscription = SingleAssignmentSubscription.new

        gate = Monitor.new

        left_obs = Observer.configure do |o|
          o.on_next do |l|
            has_left = true
            left = l

            if has_right
              res = nil
              begin
                res = result_selector.call left, right
              rescue => e
                observer.on_error e
                return
              end
              observer.on_next res
            end

            observer.on_completed if right_done
          end

          o.on_error &observer.method(:on_error)  

          o.on_completed do 
            left_done = true
            observer.on_completed if right_done
          end
        end

        right_obs = Observer.configure do |o|
          o.on_next do |r|
            has_right = true
            right = r

            if has_left
              res = nil
              begin
                res = result_selector.call left, right
              rescue => e
                observer.on_error e
                return
              end
              observer.on_next res
            end

            observer.on_completed if left_done
          end

          o.on_error &observer.method(:on_error)  

          o.on_completed do
            right_done = true
            observer.on_completed if left_done
          end
        end

        left_subscription.subscription = synchronize(gate).subscribe(left_obs)
        right_subscription.subscription = other.synchronize(gate).subscribe(right_obs)

        CompositeSubscription.new [left_subscription, right_subscription]
      end
    end

    # Concatenates the second observable sequence to the first observable sequence upon successful termination of the first.
    def concat(other)
      Observable.concat([self, other].to_enum)
    end

    # Merges elements from two observable sequences into a single observable sequence, using the specified scheduler for enumeration of and subscription to the sources.
    def merge(other, scheduler = CurrentThreadScheduler.instance)
      Observable.merge_all(scheduler, *[self, other])
    end

    # Merges elements from all inner observable sequences into a single observable sequence, limiting the number of concurrent subscriptions to inner sequences.
    def merge_concurrent(max_concurrent = 1)
      AnonymousObservable.new do |observer|
        gate = Monitor.new
        q = []
        stopped = false
        group = CompositeSubscription.new
        active = 0

        subscriber = nil
        subscriber = lambda do |xs|
          subscription = SingleAssignmentSubscription.new
          group >> subscription

          new_obs = Observer.configure do |o|
            o.on_next {|x| gate.synchronize { observer.on_next x } }
            
            o.on_error {|err| gate.synchronize { observer.on_error err } }
            
            o.on_completed do 
              group.delete subscription
              gate.synchronize do
                if q.length > 0
                  s = q.shift
                  subscriber.call s
                else
                  active -= 1
                  observer.on_completed if stopped && active == 0
                end
              end
            end
          end

          xs.subscribe new_obs
        end

        inner_obs = Observer.configure do |o|
          o.on_next do |inner_source|
            gate.synchronize do
              if active < max_concurrent
                active += 1
                subscriber.call inner_source
              else
                q >> inner_source
              end
            end
          end

          o.on_error {|err| gate.synchronize { observer.on_error err } }

          o.on_completed do
            stopped = true
            observer.on_completed if active == 0
          end
        end

        group >> subscribe(inner_obs)
      end
    end

    # Concatenates all inner observable sequences, as long as the previous observable sequence terminated successfully.
    def merge_all
      AnonymousObservable.new do |observer|
        gate = Monitor.new
        stopped = false
        m = SingleAssignmentSubscription.new
        group = CompositeSubscription.new [m]

        new_obs = Observer.configure do |o|
          o.on_next do |inner_source|
            inner_subscription = SingleAssignmentSubscription.new
            group >> inner_subscription

            inner_obs = Observer.configure do |io|
              io.on_next {|x| gate.synchronize { observer.on_next x } }
              
              io.on_error {|_| gate.synchronize { observer.on_error x } }
              
              io.on_completed do
                group.delete inner_subscription
                gate.synchronize { observer.on_completed } if stopped && group.length == 1
              end
            end

            inner_subscription.subscription = inner_source.subscribe inner_obs
          end

          o.on_error {|err| gate.synchronize { observer.on_error err } }

          o.on_completed do
            stopped = true
            gate.synchronize { observer.on_completed } if group.length == 1
          end
        end

        subscribe new_obs
      end
    end

    # Concatenates the second observable sequence to the first observable sequence upon successful or exceptional termination of the first.
    def on_error_resume_next(other)
      raise ArgumentError.new 'Other cannot be nil' unless other

      Observable.on_error_resume_next *[self, other]
    end

    # Returns the elements from the source observable sequence only after the other observable sequence produces an element.
    def skip_until(other)
      raise ArgumentError.new 'Other cannot be nil' unless other

      AnonymousObservable.new do |observer|
        source_subscription = SingleAssignmentSubscription.new
        other_subscription = SingleAssignmentSubscription.new

        open = false
        gate = Monitor.new

        source_obs = Observer.configure do |o|
          o.on_next {|x| observer.on_next x if open }
          o.on_error &observer.method(:on_error)
          o.on_completed { observer.on_completed if open }
        end

        other_obs = Observer.configure do |o|
          o.on_next do |_|
            open = true
            other_subscription.unsubscribe
          end

          o.on_error &observer.method(:on_error)
        end

        source_subscription.subscription = synchronize(gate).subscribe(source_obs)
        other_subscription.subscription = other.synchronize(gate).subscribe(other_obs)

        CompositeSubscription.new [source_subscription, other_subscription]
      end
    end

    # Transforms an observable sequence of observable sequences into an observable sequence 
    # producing values only from the most recent observable sequence.
    # Each time a new inner observable sequence is received, unsubscribe from the 
    # previous inner observable sequence.
    def latest
      AnonymousObservable.new do |observer|
        gate = Monitor.new
        inner_subscription = SerialSubscription.new
        stopped = false
        latest_num = 0
        has_latest = false

        source_obs = Observer.configure do |o|
          o.on_next do |inner_source|
            id = 0

            gate.synchronize do
              latest_num += 1
              id = latest_num
            end

            d = SingleAssignmentSubscription.new

            inner_obs = Observer.configure do |io|
              io.on_next {|x| gate.synchronize { observer.on_next x if latest_num == id } }
              io.on_error do |err| 
                gate.synchronize do 
                  has_latest = false
                  observer.on_error err if latest_num == id
                end
              end
            end

            d.subscription = inner_source.subscribe inner_obs
          end

          o.on_error {|err| gate.synchronize { observer.on_error err } }

          o.on_completed do
            gate.synchronize do
              stopped = true
              observer.on_completed unless has_latest
            end
          end
        end

        subscription = subscribe source_obs

        CompositeSubscription.new [subscription, inner_subscription]
      end
    end

    # Returns the elements from the source observable sequence until the other observable sequence produces an element.
    def take_until(other)
      raise ArgumentError.new 'other cannot be nil' unless other

      AnonymousObservable.new do |observer| 
        source_subscription = SingleAssignmentSubscription.new
        other_subscription = SingleAssignmentSubscription.new

        gate = Monitor.new

        other_obs = Observer.configure do |o|
          o.on_next {|_| observer.on_completed }
          o.on_error &observer.method(:on_error)   
        end

        other_subscription.subscription = other.synchronize(gate).subscribe(other_obs)
        source_subscription.subscription = synchronize(gate).ensures(&other_subscription.method(:unsubscribe)).subscribe(observer)

        CompositeSubscription.new [source_subscription, other_subscription]
      end
    end

    # Merges the specified observable sequences into one observable sequence by using the selector function whenever all of the observable sequences have produced an element at a corresponding index.
    def zip(*args, &result_selector)
      args.unshift(self)
      Observable.zip(*args, &result_selector)
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
              err = nil

              if disposed
                return
              else
                begin
                  current = e.next
                  has_next = true
                rescue StopIteration => _
                  # Do nothing
                rescue => e
                  err = e
                end
              end

              if err
                observer.on_error err
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

      # Merges the specified observable sequences into one observable sequence by using the selector function whenever any of the observable sequences produces an element.
      def combine_latest(*args, &result_selector)
        AnonymousObservable.new do |observer|
          result_selector ||= lambda {|*inner_args| inner_args }

          n = args.length
          has_value = Array.new(n, false)
          has_value_all = false

          values = Array.new(n)
          is_done = Array.new(n, false)

          next_item = lambda do |i|
            has_value[i] = true
            if has_value_all || (has_value_all = has_value.all?)
              res = nil
              begin
                res = result_selector.call(*values)
              rescue => e
                observer.on_error e
                return
              end

              observer.on_next(res)
            elsif enumerable_select_with_index(is_done) {|_, j| j != i} .all?
              observer.on_completed
              return
            end
          end

          done = lambda do |i|
            is_done[i] = true
            observer.on_completed if is_done.all?
          end

          gate = Monitor.new
          subscriptions = Array.new(n) do |i|
            sas = SingleAssignmentSubscription.new

            sas_obs = Observer.configure do |o|
              o.on_next do |x|
                values[i] = x
                next_item.call i
              end

              o.on_error &observer.method(:on_error)   

              o.on_completed { done.call i }
            end

            sas.subscription = args[i].synchronize(gate).subscribe(sas_obs)

            sas
          end

          CompositeSubscription.new subscriptions
        end
      end

      # Concatenates all of the specified observable sequences, as long as the previous observable sequence terminated successfully.
      def concat(*args)
        AnonymousObservable.new do |observer|
          disposed = false
          e = args.length == 1 && args[0].is_a?(Enumerator) ? args[0] : args.to_enum
          subscription = SerialSubscription.new
          gate = AsyncLock.new

          cancelable = CurrentThreadScheduler.instance.schedule_recursive lambda {|this|
            gate.wait do
              current = nil
              has_next = false
              err = nil

              if disposed
                return
              else
                begin
                  current = e.next
                  has_next = true
                rescue StopIteration => _
                  # Do nothing
                rescue => e
                  err = e
                end
              end

              if err
                observer.on_error err
                return
              end

              unless has_next
                observer.on_completed
                return
              end

              d = SingleAssignmentSubscription.new
              subscription.subscription = d

              new_obs = Observer.configure do |o|
                o.on_next &observer.method(:on_next)
                o.on_error &observer.method(:on_error)
                o.on_completed { this.call }
              end

              current.subscribe new_obs
            end
          }

          CompositeSubscription.new [subscription, cancelable, Subscription.create { gate.wait { disposed = true }}]
        end
      end

      # Merges elements from all observable sequences in the given enumerable sequence into a single observable sequence, limiting the number of concurrent subscriptions to inner sequences, and using the specified scheduler for enumeration of and subscription to the sources.
      def merge_concurrent(max_concurrent, scheduler = CurrentThreadScheduler.instance, *args)
        Observable.from_array(args, scheduler).merge_concurrent(max_concurrent)
      end

      # Merges elements from all of the specified observable sequences into a single observable sequence, using the specified scheduler for enumeration of and subscription to the sources.
      def merge_all(scheduler = CurrentThreadScheduler.instance, *args)
        Observable.from_array(args, scheduler).merge_all
      end

      # Concatenates all of the specified observable sequences, even if the previous observable sequence terminated exceptionally.
      def on_error_resume_next(*args)
        AnonymousObservable.new do |observer|
          gate = AsyncLock.new
          disposed = false
          e = args.length == 1 && args[0].is_a?(Enumerator) ? args[0] : args.to_enum
          subscription = SerialSubscription.new

          cancelable = CurrentThreadScheduler.schedule_recursive do |this|
            gate.wait do
              current = nil
              has_next = false
              err = nil

              if !disposed
                begin
                  current = e.next
                  has_next = true
                rescue StopIteration => _
                  # Do nothing
                rescue => e
                  err = e
                end
              else
                return
              end

              if err
                observer.on_error err
                return
              end

              unless has_next
                observer.on_completed
                return
              end

              d = SingleAssignmentSubscription.new
              subscription.subscription = d

              new_obs = Observer.configure do |o|
                o.on_next &observer.method(:on_next)
                o.on_error {|_| this.call }
                o.on_completed { this.call }
              end

              d.subscription = current.subscribe new_obs
            end
          end

          CompositeSubscription.new [subscription, cancelable, Subscription.create { gate.wait { disposed = true } }]
        end
      end

      # Merges the specified observable sequences into one observable sequence by using the selector function whenever all of the observable sequences have produced an element at a corresponding index.
      def zip(*args, &result_selector)
        AnonymousObservable.new do |observer|
          result_selector ||= lambda {|*inner_args| inner_args }
          n = args.length

          queues = Array.new(n) {|i| Array.new }
          is_done = Array.new(n, false)

          next_action = lambda do |i|
            if queues.all? {|q| q.length > 0 }
              res = queues.map {|q| q.shift }
              observer.on_next(result_selector.call *res)
            elsif enumerable_select_with_index(is_done) {|x, j| j != i } .all?
              observer.on_completed
            end
          end

          done = lambda do |i|
            is_done[i] = true
            observer.on_completed if is_done.all?
          end

          gate = Monitor.new

          subscriptions = Array.new(n) do |i|
            sas = SingleAssignmentSubscription.new

            sas_obs = Observer.configure do |o|
              o.on_next do |x|
                queues[i].push(x)
                next_action.call i
              end

              o.on_error &observer.method(:on_error)

              o.on_completed { done.call i }
            end

            sas.subscription = args[i].synchronize(gate).subscribe(sas_obs)
            sas
          end

          subscriptions.push(Subscription.create { queues.each {|q| q = [] }})

          CompositeSubscription.new subscriptions
        end
      end

      private

      def enumerable_select_with_index(arr, &block)
        [].tap do |new_arr|
          arr.each_with_index do |item, index|
            new_arr.push item if block.call item, index
          end
        end
      end
    end
  end
end
