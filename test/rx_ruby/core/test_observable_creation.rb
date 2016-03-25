# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require "#{File.dirname(__FILE__)}/../../test_helper"

class TestObservableCreation < Minitest::Test
  include RxRuby::ReactiveTest

  # Create Methods

  def test_create_next
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do 
      RxRuby::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        RxRuby::Subscription.empty
      end
    end

    assert_messages [on_next(200, 1), on_next(200, 2)], res.messages
  end

  def test_create_next_nil
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do 
      RxRuby::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        nil
      end
    end
    
    assert_messages [on_next(200, 1), on_next(200, 2)], res.messages
  end

  def test_create_completed
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do 
      RxRuby::Observable.create do |obs|
        obs.on_completed
        obs.on_next 100
        obs.on_error RuntimeError.new
        obs.on_completed
        nil
      end
    end
    
    assert_messages [on_completed(200)], res.messages    
  end

  def test_create_error
    err = RuntimeError.new
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do 
      RxRuby::Observable.create do |obs|
        obs.on_error err
        obs.on_next 100
        obs.on_error RuntimeError.new
        obs.on_completed
        nil
      end
    end
    
    assert_messages [on_error(200, err)], res.messages     
  end

  def test_create_unsubscribe
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do 
      RxRuby::Observable.create do |obs|
        stopped = false
        
        obs.on_next 1
        obs.on_next 2

        scheduler.schedule_relative(600, lambda {
          obs.on_next 3 unless stopped  
        })

        scheduler.schedule_relative(700, lambda {
          obs.on_next 4 unless stopped  
        })  

        scheduler.schedule_relative(900, lambda {
          obs.on_next 5 unless stopped  
        })

        scheduler.schedule_relative(1100, lambda {
          obs.on_next 6 unless stopped  
        })                

        RxRuby::Subscription.create { stopped = true }
      end
    end
    
    msgs = [
      on_next(200, 1),
      on_next(200, 2),
      on_next(800, 3),
      on_next(900, 4)
    ]
    assert_messages msgs, res.messages      
  end

  def test_create_observer_raises
    assert_raises(RuntimeError) do 

      observable = RxRuby::Observable.create do |obs|
        obs.on_next 1
        nil
      end

      observer = RxRuby::Observer.configure do |o|
        o.on_next {|x| raise RuntimeError.new }
      end

      observable.subscribe observer
    end

    assert_raises(RuntimeError) do 

      observable = RxRuby::Observable.create do |obs|
        obs.on_error RuntimeError.new
        nil
      end

      observer = RxRuby::Observer.configure do |o|
        o.on_error {|err| raise RuntimeError.new }
      end

      observable.subscribe observer
    end

    assert_raises(RuntimeError) do 

      observable = RxRuby::Observable.create do |obs|
        obs.on_completed
        nil
      end

      observer = RxRuby::Observer.configure do |o|
        o.on_completed { raise RuntimeError.new }
      end

      observable.subscribe observer
    end    
  end

  # Defer Method tests

  def test_defer_complete
    scheduler = RxRuby::TestScheduler.new 

    invoked = 0
    xs = nil

    res = scheduler.configure do 
      RxRuby::Observable.defer do
        invoked += 1

        xs = scheduler.create_cold_observable(
          on_next(100, scheduler.clock),
          on_completed(200)
        )
        xs
      end
    end

    msgs = [on_next(300, 200), on_completed(400)]
    assert_messages msgs, res.messages    

    assert_equal 1, invoked

    assert_subscriptions [subscribe(200, 400)], xs.subscriptions 
  end

  def test_defer_error
    scheduler = RxRuby::TestScheduler.new 

    invoked = 0
    xs = nil
    err = RuntimeError.new

    res = scheduler.configure do 
      RxRuby::Observable.defer do
        invoked += 1

        xs = scheduler.create_cold_observable(
          on_next(100, scheduler.clock),
          on_error(200, err)
        )
        xs
      end
    end

    msgs = [on_next(300, 200), on_error(400, err)]
    assert_messages msgs, res.messages    

    assert_equal 1, invoked

    assert_subscriptions [subscribe(200, 400)], xs.subscriptions     
  end

  def test_defer_unsubscribe
    scheduler = RxRuby::TestScheduler.new 

    invoked = 0
    xs = nil

    res = scheduler.configure do 
      RxRuby::Observable.defer do
        invoked += 1

        xs = scheduler.create_cold_observable(
          on_next(100, scheduler.clock),
          on_next(200, invoked),
          on_next(1100, 1000)
        )
        xs
      end
    end

    msgs = [on_next(300, 200), on_next(400, 1)]
    assert_messages msgs, res.messages    

    assert_equal 1, invoked

    assert_subscriptions [subscribe(200, 1000)], xs.subscriptions     
  end

  def test_defer_raise
    scheduler = RxRuby::TestScheduler.new 

    invoked = 0
    err = RuntimeError.new

    res = scheduler.configure do 
      RxRuby::Observable.defer do
        invoked += 1
        raise err
      end
    end

    msgs = [on_error(200, err)]
    assert_messages msgs, res.messages    

    assert_equal 1, invoked     
  end

  # Empty methods

  def test_empty_basic
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.empty(scheduler)
    end

    msgs = [on_completed(201)]
    assert_messages msgs, res.messages       
  end

  def test_empty_disposed
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure({:disposed => 200}) do
      RxRuby::Observable.empty(scheduler)
    end

    msgs = []
    assert_messages msgs, res.messages   
  end

  def test_empty_observer_raises
    scheduler = RxRuby::TestScheduler.new

    xs = RxRuby::Observable.empty(scheduler)

    observer = RxRuby::Observer.configure do |obs|
      obs.on_completed { raise RuntimeError.new }
    end

    xs.subscribe observer

    assert_raises(RuntimeError) { scheduler.start }
  end

  # Generate methods

  def test_generate_finite
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.generate(
        0,
        lambda { |x| return x <= 3 },
        lambda { |x| return x + 1 },
        lambda { |x| return x },
        scheduler)
    end

    msgs = [
      on_next(201, 0),
      on_next(202, 1),
      on_next(203, 2),
      on_next(204, 3),
      on_completed(205)      
    ]
    assert_messages msgs, res.messages
  end

  def test_generate_condition_raise
    scheduler = RxRuby::TestScheduler.new
    err = RuntimeError.new

    res = scheduler.configure do
      RxRuby::Observable.generate(
        0,
        lambda { |x| raise err },
        lambda { |x| return x + 1 },
        lambda { |x| return x },
        scheduler)
    end

    msgs = [
      on_error(201, err)  
    ]
    assert_messages msgs, res.messages
  end

  def test_generate_raise_result_selector
    scheduler = RxRuby::TestScheduler.new
    err = RuntimeError.new

    res = scheduler.configure do
      RxRuby::Observable.generate(
        0,
        lambda { |x| return true },
        lambda { |x| return x + 1 },
        lambda { |x| raise err },
        scheduler)
    end

    msgs = [
      on_error(201, err)  
    ]
    assert_messages msgs, res.messages    
  end

  def test_generate_raise_iterate
    scheduler = RxRuby::TestScheduler.new
    err = RuntimeError.new

    res = scheduler.configure do
      RxRuby::Observable.generate(
        0,
        lambda { |x| return true },
        lambda { |x| raise err },
        lambda { |x| return x },
        scheduler)
    end

    msgs = [
      on_next(201, 0),
      on_error(202, err)
    ]
    assert_messages msgs, res.messages    
  end

  def test_generate_dispose
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure(:disposed => 203) do
      RxRuby::Observable.generate(
        0,
        lambda { |x| return x <= 3 },
        lambda { |x| return x + 1 },
        lambda { |x| return x },
        scheduler)
    end

    msgs = [
      on_next(201, 0),
      on_next(202, 1),     
    ]
    assert_messages msgs, res.messages
  end

  # Never methods

  def test_never_basic
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.never
    end

    msgs = []
    assert_messages msgs, res.messages
  end

  # Range methods

  def test_range_zero
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.range(0, 0, scheduler)
    end

    msgs = [on_completed(201)]
    assert_messages msgs, res.messages    
  end

  def test_range_one
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.range(0, 1, scheduler)
    end

    msgs = [on_next(201, 0), on_completed(202)]
    assert_messages msgs, res.messages      
  end

  def test_range_five
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.range(10, 5, scheduler)
    end

    msgs = [
      on_next(201, 10),
      on_next(202, 11),
      on_next(203, 12),
      on_next(204, 13),
      on_next(205, 14),
      on_completed(206)
    ]
    assert_messages msgs, res.messages      
  end

  def test_range_dispose
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure(:disposed => 204) do
      RxRuby::Observable.range(-10, 5, scheduler)
    end

    msgs = [
      on_next(201, -10),
      on_next(202, -9),
      on_next(203, -8),
    ]
    assert_messages msgs, res.messages 
  end

  # Repeat methods
=begin
# the clock is actually off, because of not using the `scheduler.schedule_recursive`
  def test_repeat_value_count_zero
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.repeat(42, 0, scheduler)
    end

    msgs = [
      on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_repeat_value_once
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.repeat(42, 1, scheduler)
    end

    msgs = [
        on_next(201, 42),
        on_completed(202)
    ]
    assert_messages msgs, res.messages
  end
=end

  def test_repeat_infinitely_dispose
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure(:disposed => 203) do
      RxRuby::Observable.repeat_infinitely({a: 1}, scheduler)
    end

    msgs = [
        on_next(201, {a: 1}),
        on_next(202, {a: 1})
    ]
    assert_messages msgs, res.messages
  end

  # of_enumerable/of_enumerator
  def test_of_enumerable_empty
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.of_enumerable([], scheduler)
    end

    msgs = [
        on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_of_enumerable_simple
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.of_enumerable(%w(foo bar baz), scheduler)
    end

    msgs = [
        on_next(201, 'foo'),
        on_next(202, 'bar'),
        on_next(203, 'baz'),
        on_completed(204)
    ]
    assert_messages msgs, res.messages
  end


  def test_of_enumerator_empty
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.of_enumerator([].to_enum, scheduler)
    end

    msgs = [
        on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_of_enumerator_error
    scheduler = RxRuby::TestScheduler.new
    err = RuntimeError.new
    fibs = Enumerator.new do |x|
      a = b = 1
      6.times do
        x << a
        a, b = b, a + b
      end
      raise err
    end
    res = scheduler.configure do
      RxRuby::Observable.of_enumerator(fibs, scheduler)
    end

    msgs = [
        on_next(201, 1),
        on_next(202, 1),
        on_next(203, 2),
        on_next(204, 3),
        on_next(205, 5),
        on_next(206, 8),
        on_error(207, err)
    ]
    assert_messages msgs, res.messages
  end

  def test_of_enumerator_infinite_dispose
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure(:disposed => 205) do
      RxRuby::Observable.of_enumerator([42].cycle, scheduler)
    end

    msgs = [
        on_next(201, 42),
        on_next(202, 42),
        on_next(203, 42),
        on_next(204, 42)
    ]
    assert_messages msgs, res.messages
  end

  # from_array methods
  def test_from_array_empty
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.from_array([], scheduler)
    end

    msgs = [
        on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_from_array_simple
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure do
      RxRuby::Observable.from_array([1, 2, 3], scheduler)
    end

    msgs = [
        on_next(201, 1),
        on_next(202, 2),
        on_next(203, 3),
        on_completed(204)
    ]
    assert_messages msgs, res.messages
  end

  def test_from_array_complex_dispose
    scheduler = RxRuby::TestScheduler.new

    res = scheduler.configure(:disposed => 204) do
      RxRuby::Observable.from_array([[], [[]], [[[]]], [[[[]]]]], scheduler)
    end

    msgs = [
        on_next(201, []),
        on_next(202, [[]]),
        on_next(203, [[[]]])
    ]
    assert_messages msgs, res.messages
  end
end
