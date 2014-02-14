# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/subscriptions/subscription'
require 'rx/core/observer'
require 'rx/core/observable'

module RX

  module Observable

    # Hides the identity of an observable sequence.
    def as_observable
      AnonymousObservable.new &subscribe
    end

    # Projects each element of an observable sequence into zero or more buffers which are produced based on element count information.
    def buffer_with_count(count, skip = count)
      window(count, skip).flat_map(&method(:to_a)).filter {|x| x.length > 0 }
    end

    # Dematerializes the explicit notification values of an observable sequence as implicit notifications.
    def dematerialize
      AnonymousObservable.new do |observer|
        
        new_obs = RX::Observer.configure do |o|
          o.on_next {|x| x.accept observer }
          o.on_error &observer.method(:on_error)
          o.on_completed &observer.method(:on_completed)              
        end

        subscribe new_obs
      end
    end

    # Returns an observable sequence that contains only distinct contiguous elements according to the optional key_selector.
    def distinct_until_changed(&key_selector)
      key_selector ||= lambda {|x| x}
      AnonymousObservable.new do |observer|
        current_key = nil
        has_current = nil

        new_obs = RX::Observer.configure do |o|
          o.on_next do |value|
            key = nil
            begin
              key = key_selector.call value
            rescue => err
              observer.on_error err
              return
            end

            if !current_key || key != current_key
              has_current = true
              current_key = key
              observer.on_next value
            end
          end

          o.on_error &observer.method(:on_error)
          o.on_completed &observer.method(:on_completed)              
        end

        subscribe new_obs
      end
    end

    # Invokes the observer's methods for each message in the source sequence.
    # This method can be used for debugging, logging, etc. of query behavior by intercepting the message stream to run arbitrary actions for messages on the pipeline.
    def tap(observer)
      raise 'Observer cannot be nil' unless observer
      AnonymousObservable.new do |obs|
        new_obs = RX::Observer.configure do |o|

          o.on_next do |value|
            begin
              observer.on_next value
            rescue => err
              obs.on_error err
            end

            obs.on_next value
          end

          o.on_error do |err|
            begin
              observer.on_error err
            rescue => e
              obs.on_error e
            end

            obs.on_error err
          end          

          o.on_completed do
            begin
              observer.on_completed
            rescue => err
              obs.on_error err
            end

            obs.on_completed
          end

        end

        subscribe new_obs
      end
    end

    # Invokes a specified action after the source observable sequence terminates gracefully or exceptionally.
    def ensures
      AnonymousObservable.new do |observer|
        subscription = subscribe observer
        Subscription.create do 
          begin
            subscription.unsubscribe
          ensure
            yield
          end
        end
      end
    end

    # Ignores all elements in an observable sequence leaving only the termination messages.
    def ignore_elements
      AnonymousObservable.new do |observer|
        new_obs = RX::Observer.configure do |o|
          o.on_next {|x| }
          o.on_error &observer.method(:on_error)
          o.on_completed &observer.method(:on_completed)  
        end

        subscribe new_obs
      end
    end

    # Materializes the implicit notifications of an observable sequence as explicit notification values.
    def materialize
      AnonymousObservable.new do |observer|
        new_obs = RX::Observer.configure do |o|

          o.on_next {|x| observer.on_next(Notification.create_on_next x) }

          o.on_error do |err|
            observer.on_next(Notification.create_on_next err)
            observer.on_completed
          end

          o.on_completed do
            observer.on_next(Notification.create_on_completed)
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    # Repeats the observable sequence indefinitely.
    def repeat_infinitely
      concat_enumerator(enumerator_repeat_infinitely(self))
    end

    # Repeats the observable sequence a specified number of times.
    def repeat(repeat_count)
      concat_enumerator(enumerator_repeat_times(repeat_count, self))
    end

    # Repeats the source observable sequence until it successfully terminates.
    def retry_infinitely
      rescue_error_enumerator(enumerator_repeat_infinitely(self))
    end

    # Repeats the source observable sequence the specified number of times or until it successfully terminates.
    def retry(retry_count)
      rescue_error_enumerator(enumerator_repeat_times(retry_count, self))
    end

    # Applies an accumulator function over an observable sequence and returns each intermediate result. 
    # The optional seed value is used as the initial accumulator value.
    # For aggregation behavior with no intermediate results, see Observable.reduce.
    def scan(*args, &block)
      has_seed = false
      seed = nil
      action = nil

      # Argument parsing to support:
      # 1. (seed, Symbol)
      # 2. (seed, &block)
      # 3. (Symbol)
      # 4. (&block)
      if args.length == 2 && args[1].is_a?(Symbol)
        seed = args[0]
        action = args[1].to_proc
        has_seed = true
      elsif args.length == 1 && block_given?
        seed = args[0]
        has_seed = true
        action = block
      elsif args.length == 1 && args[0].is_a?(Symbol)
        action = args[0].to_proc
      elsif args.length == 0 && block_given?
        action = block
      else
        raise 'Invalid arguments'
      end

      AnonymousObservable.new do |observer|

        has_accumulation = false
        accumulation = nil
        has_value = false

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            begin
              has_value = true unless has_value

              if has_accumulation
                accumulation = action.call(accumulation, x)
              else
                accumulation = has_seed ? action.call(seed, x) : x
                has_accumulation = true
              end
            rescue => err
              observer.on_error err
              return
            end

            observer.on_next accumulation
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do 
            observer.on_next seed if !has_value && has_seed
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    def enumerator_repeat_times(num, value)
      Enumerator.new do |y|
        num.times do |i|
          y << value
        end
      end
    end

    def enumerator_repeat_infinitely(value)
      Enumerator.new do |y|
        while true
          y << value
        end
      end
    end

  end
end
