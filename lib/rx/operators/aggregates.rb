# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/subscriptions/composite_subscription'
require 'rx/core/observer'
require 'rx/core/observable'
require 'rx/operators/single'
require 'rx/operators/standard_query_operators'

module RX

  module Observable

    # Internal method to get the final value
    # @return [RX::Observable]
    def final
      AnonymousObservable.new do |observer|
        value = nil
        has_value = false

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            value = x
            has_value = true
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            if has_value
              observer.on_next value
              observer.on_completed
            else
              observer.on_error(RuntimeError.new 'Sequence contains no elements')
            end
          end
        end

        subscribe new_obs
      end
    end

    # Applies an accumulator function over an observable sequence, returning the result of the aggregation as a single
    # element in the result sequence. The specified seed value is used as the initial accumulator value.
    # For aggregation behavior with incremental intermediate results, see RX::Observable.scan
    # @return [RX::Observable]
    def reduce(*args, &block)
      # Argument parsing to support:
      # 1. (seed, Symbol) || (seed, &block)
      # 2. (Symbol) || (&block)
      if (args.length == 2 && args[1].is_a?(Symbol)) || (args.length == 1 && block_given?)
        scan(*args, &block).start_with(args[0]).final
      elsif (args.length == 1 && args[0].is_a?(Symbol)) || (args.length == 0 && block_given?)
        scan(*args, &block).final
      else
        raise ArgumentError.new 'Invalid arguments'
      end
    end

    # Determines whether all elements of an observable sequence satisfy a condition if block given, else if all are
    # true
    # @param [Proc] block
    # @return [RX::Observable]
    def all?(&block)
      block ||= lambda { |_| true }
      select {|v| !(block.call v)}.
      any?.
      map {|b| !b }
    end

    # Determines whether no elements of an observable sequence satisfy a condition if block given, else if all are
    # false
    # @param [Proc] block
    # @return [RX::Observable]
    def none?(&block)
      block ||= lambda { |_| true }
      select {|v| !(block.call v)}.
      any?
    end

    # Determines whether any element of an observable sequence satisfies a condition if a block is given else if
    # there are any items in the observable sequence.
    # @return [RX::Observable]
    def any?(&block)
      return map(&block).any? if block_given?
      AnonymousObservable.new do |observer|
        new_obs = Observer.configure do |o|
          o.on_next do |_|
            observer.on_next true
            observer.on_completed
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            observer.on_next false
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    # Computes the average of an observable sequence of values that are optionally obtained by invoking a
    # transform function on each element of the input sequence if a block is given
    # @param [Object] block
    # @return [RX::Observable]
    def average(&block)
      return map(&block).average if block_given?
      scan({:sum => 0, :count => 0}) {|prev, current| {:sum => prev[:sum] + current, :count => prev[:count] + 1 }}.
      final.
      map {|x|
        raise 'Sequence contains no elements' if x[:count] == 0
        x[:sum] / x[:count]
      }
    end

    # Determines whether an observable sequence contains a specified element.
    # @param [Object] item The value to locate in the source sequence.
    # @return [RX::Observable] An observable sequence containing a single element determining whether the source
    # sequence contains an element that has the specified value.
    def contains?(item)
      select {|x| x.eql? item}.any?
    end

    # Returns an observable sequence containing a number that represents how many elements in the specified
    # observable sequence satisfy a condition if the block is given, else the number of items in the observable
    # sequence
    def count(&block)
      return select &block .count if block_given?
      reduce(0) {|c, _| c + 1 }
    end

    # Returns the element at a specified index in a sequence.
    # @param [Numeric] index The zero-based index of the element to retrieve.
    # @return [RX::Observable] An observable sequence that produces the element at the specified position in the
    # source sequence.
    def element_at(index)
      raise ArgumentError.new 'index cannot be less than zero' if index < 0
      AnonymousObservable.new do |observer|
        i = index
        new_obs = Observer.configure do |o|
          o.on_next do |value|
            if i == 0
              observer.on_next value
              observer.on_completed
            end

            i -= 1
          end

          o.on_error &observer.method(:on_error)
          o.on_completed { raise 'Sequence contains no elements' }
        end

        subscribe new_obs
      end
    end

    # Returns the element at a specified index in a sequence or a default value if the index is out of range.
    # @param [Numeric] index The zero-based index of the element to retrieve.
    # @param [Object] default_value The default value to use if the index is out of range.
    def element_at_or_default(index, default_value = nil)
      raise ArgumentError.new 'index cannot be less than zero' if index < 0
      AnonymousObservable.new do |observer|
        i = index
        new_obs = Observer.configure do |o|
          o.on_next do |value|
            if i == 0
              observer.on_next value
              observer.on_completed
            end

            i -= 1
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            observer.on_next default_value
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    # Returns the first element of an observable sequence that satisfies the condition in the predicate if a block is
    # given, else the first item in the observable sequence.
    # @param [Proc] block Optional predicate function to evaluate for elements in the source sequence.
    # @return [RX::Observable] Sequence containing the first element in the observable sequence that satisfies the
    # condition in the predicate if a block is given, else the first element.
    def first(&block)
      return select &block .first if block_given?
      AnonymousObservable.new do |observer|
        new_obs = Observer.configure do |o|
          o.on_next do |x|
            observer.on_next x
            observer.on_completed
          end

          o.on_error &observer.method(:on_error)
          o.on_completed { raise 'Sequence contains no elements' }
        end

        subscribe new_obs
      end
    end

    # Returns the first element of an observable sequence that satisfies the condition in the predicate if given,
    # or a default value if no such element exists.
    # @param [Object] default_value The default value to use if the sequence is empty.
    # @param [Proc] block An optional predicate function to evaluate for elements in the source sequence.
    # @return [RX::Observable] Sequence containing the first element in the observable sequence that satisfies the
    # condition in the predicate if given, or a default value if no such element exists.
    def first_or_default(default_value = nil, &block)
      return select &block .first_or_default(default_value) if block_given?
      AnonymousObservable.new do |observer|
        new_obs = Observer.configure do |o|
          o.on_next do |x|
            observer.on_next x
            observer.on_completed
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            observer.on_next default_value
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    # Determines whether an observable sequence is empty.
    # @return [RX::Observable] An observable sequence containing a single element determining whether the source
    # sequence is empty.
    def empty?
      any?.map {|b| !b }
    end

    # Returns the last element of an observable sequence that satisfies the condition in the predicate if the block is
    # given, else the last element in the observable sequence.
    # @param [Proc] block An predicate function to evaluate for elements in the source sequence.
    # @return {RX::Observable} Sequence containing the last element in the observable sequence that satisfies the
    # condition in the predicate if given, or the last element in the observable sequence.
    def last(&block)
      return select &block .last if block_given?
      AnonymousObservable.new do |observer|

        value = nil
        seen_value = false

        new_obs = Observer.configure do |o|
          o.on_next do |v|
            value = v
            seen_value = true
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            if seen_value
              observer.on_next value
              observer.on_completed
            else
              observer.on_error(RuntimeError.new 'Sequence contains no elements' )
            end
          end
        end

        subscribe new_obs
      end
    end

    # Returns the last element of an observable sequence that satisfies the condition in the predicate if given, or
    # a default value if no such element exists.
    # @param [Object] default_value The default value to use if the sequence is empty.
    # @param [Proc] block An predicate function to evaluate for elements in the source sequence.
    # @return {RX::Observable} Sequence containing the last element in the observable sequence that satisfies the
    # condition in the predicate if given, or a default value if no such element exists.
    def last_or_default(default_value = nil, &block)
      return select &block .last_or_default(default_value) if block_given?
      AnonymousObservable.new do |observer|

        value = nil
        seen_value = false

        new_obs = Observer.configure do |o|
          o.on_next do |v|
            value = v
            seen_value = true
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            observer.on_next (seen_value ? value : default_value)
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    # Returns the maximum element in an observable sequence.
    # @param [Proc] block An optional selector function to produce an element.
    # @return [RX::Observable] The maximum element in an observable sequence.
    def max(&block)
      return map &block .max if block_given?
      max_by {x| x} .map {|x| x[0] }
    end

    # Returns the elements in an observable sequence with the maximum key value.
    # @param [Proc] block Key selector function.
    # @return [RX::Observable] An observable sequence containing a list of zero or more elements that have a maximum
    # key value.
    def max_by(&block)
      extrema_by(&block)
    end

    # Returns the minimum element in an observable sequence.
    # @param [Proc] block An optional selector function to produce an element.
    # @return [RX::Observable] The minimum element in an observable sequence.
    def min(&block)
      return map &block .min if block_given?
      min_by {|x| x} .map {|x| x[0] }
    end

    # Returns the elements in an observable sequence with the minimum key value.
    # @param [Proc] block Key selector function.
    # @return [RX::Observable] >An observable sequence containing a list of zero or more elements that have a
    # minimum key value.
    def min_by(&block)
      extrema_by(true, &block)
    end

    # Determines whether two sequences are equal by comparing the elements pairwise.
    # @param [RX::Observable] other Other observable sequence to compare.
    # @return [RX::Observable] An observable sequence that contains a single element which indicates whether both
    # sequences are of equal length and their corresponding elements are equal.
    def sequence_eql?(other)
      AnonymousObservable.new do |observer|
        gate = Mutex.new
        left_done = false
        right_done = false
        left_queue = []
        right_queue = []

        obs1 = Observer.configure do |o|
          o.on_next do |x|
            gate.synchronize do
              if right_queue.length > 0
                v = right_queue.shift
                equal = x == v

                unless equal
                  observer.on_next false
                  observer.on_completed
                end
              elsif right_done
                observer.on_next false
                observer.on_completed
              else
                left_queue.push x
              end
            end
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            gate.synchronize do
              left_done = true
              if left_queue.length == 0
                if right_queue.length > 0
                  observer.on_next false
                  observer.on_completed
                elsif right_done
                  observer.on_next true
                  observer.on_completed
                end
              end
            end
          end
        end

        subscription1 = subscribe obs1

        obs2 = Observer.configure do |o|
          o.on_next do |x|
            gate.synchronize do
              if left_queue.length > 0
                v = left_queue.shift
                equal = x == v

                unless equal
                  observer.on_next false
                  observer.on_completed
                end
              elsif left_done
                observer.on_next false
                observer.on_completed
              else
                right_queue.push x
              end
            end
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            gate.synchronize do
              right_done = true
              if right_queue.length == 0
                if left_queue.length > 0
                  observer.on_next false
                  observer.on_completed
                elsif left_done
                  observer.on_next true
                  observer.on_completed
                end
              end
            end
          end
        end

        subscription2 = other.subscribe obs2

        CompositeSubscription.new [subscription1, subscription2]
      end
    end

    # Returns the only element of an observable sequence, and reports an exception if there is not exactly one
    # element in the observable sequence.
    # @param [Proc] block A predicate function to evaluate for elements in the source sequence.
    # @return [RX::Observable] >Sequence containing the single element in the observable sequence.
    def single(&block)
      return select &block .single if block_given?
      AnonymousObservable.new do |observer|
        seen_value = false
        value = nil

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            if seen_value
              observer.on_error(RuntimeError.new 'More than one element produced')
            else
              value = x
              seen_value = true
            end
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            if seen_value
              observer.on_next value
              observer.on_completed
            else
              observer.on_error(RuntimeError.new 'Sequence contains no elements')
            end
          end
        end

        subscribe new_obs
      end
    end

    # Returns the only element of an observable sequence, or a default value if the observable sequence is empty;
    # this method reports an exception if there is more than one element in the observable sequence.
    # @param [Object] default_value The default value if no value is provided
    # @param [Proc] block A predicate function to evaluate for elements in the source sequence.
    # @return [RX::Observable] Sequence containing the single element in the observable sequence, or a default value
    # if no such element exists.
    def single_or_default(default_value = nil, &block)
      return select &block .single_or_default(default_value) if block_given?
      AnonymousObservable.new do |observer|
        seen_value = false
        value = nil

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            if seen_value
              observer.on_error(RuntimeError.new 'More than one element produced')
            else
              value = x
              seen_value = true
            end
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            observer.on_next (seen_value ? value : default_value)
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    # Computes the sum of a sequence of values.
    # @param [Proc] block Optional block used to obtain the value to sum.
    # @return [RX::Observable] An observable sequence containing a single element with the sum of the values in the
    # source sequence.
    def sum(&block)
      return map &block .sum if block_given?
      reduce(0) {|acc, x| acc + x}
    end

    # Creates an array from an observable sequence.
    # @return [RX::Observable] An array created from an observable sequence.
    def to_a
      AnonymousObservable.new do |observer|
        arr = []
        self.subscribe(
          arr.method(:push),
          observer.method(:on_error),
          lambda {
            observer.on_next arr
            observer.on_completed
          })
      end
    end

    class HashConfiguration
      DEFAULT_SELECTOR = lambda {|x| x}

      attr_reader :key_selector_block, :value_selector_block

      def initialize
        @key_selector_block = DEFAULT_SELECTOR
        @value_selector_block = DEFAULT_SELECTOR
      end

      def key_selector(&key_selector_block)
        @key_selector_block = key_selector_block
      end

      def value_selector(&value_selector_block)
        @on_error_block = value_selector_block
      end
    end

    # Creates a Hash from the observable collection.  Note that any duplicate keys will be overwritten.
    # @return [RX::Observable] A Hash created from an observable sequence.
    def to_h
      h = HashConfiguration.new
      yield h if block_given?
      reduce(Hash.new) do |acc, x|
        acc[h.key_selector_block.call x] = h.value_selector_block.call x
        acc
      end
    end

    private

    def extrema_by(is_min = false, &block)
      AnonymousObservable.new do |observer|
        has_value = false
        last_key = nil
        list = []

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            key = nil
            begin
              key = block.call(x)
            rescue => e
              observer.on_error e
              return
            end

            comparison = 0
            if has_value
              comparison = key<=>last_key
              comparison = comparison * -1 if is_min
            else
              has_value = true
              last_key = key
            end

            if comparison > 0
              last_key = key
              list = []
            end
            list.push x if comparison >= 0
          end

          o.on_error &observer.method(:on_error)

          o.on_completed do
            observer.on_next list
            observer.on_completed
          end

        end

        subscribe new_obs
      end
    end

  end
end
