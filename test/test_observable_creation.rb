# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestObservableCreation < MiniTest::Unit::TestCase
  include RX::ReactiveTest

  # Create Methods

  def test_create_next
    scheduler = RX::TestScheduler.new

    res = scheduler.configure do 
      RX::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        RX::Subscription.empty
      end
    end

    assert_messages [on_next(200, 1), on_next(200, 2)], res.messages
  end

  def test_create_next_nil
    scheduler = RX::TestScheduler.new

    res = scheduler.configure do 
      RX::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        nil
      end
    end
    
    assert_messages [on_next(200, 1), on_next(200, 2)], res.messages
  end

  def test_create_completed
    scheduler = RX::TestScheduler.new

    res = scheduler.configure do 
      RX::Observable.create do |obs|
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
    scheduler = RX::TestScheduler.new

    res = scheduler.configure do 
      RX::Observable.create do |obs|
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
    err = RuntimeError.new
    scheduler = RX::TestScheduler.new

    res = scheduler.configure do 
      RX::Observable.create do |obs|
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

        RX::Subscription.create { stopped = true }
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

      observable = RX::Observable.create do |obs|
        obs.on_next 1
        nil
      end

      observer = RX::Observer.configure do |o|
        o.on_next {|x| raise RuntimeError.new }
      end

      observable.subscribe observer
    end

    assert_raises(RuntimeError) do 

      observable = RX::Observable.create do |obs|
        obs.on_error RuntimeError.new
        nil
      end

      observer = RX::Observer.configure do |o|
        o.on_error {|err| raise RuntimeError.new }
      end

      observable.subscribe observer
    end

    assert_raises(RuntimeError) do 

      observable = RX::Observable.create do |obs|
        obs.on_completed
        nil
      end

      observer = RX::Observer.configure do |o|
        o.on_completed { raise RuntimeError.new }
      end

      observable.subscribe observer
    end    
  end

  # Defer Method tests

=begin
  def test_defer_complete
    scheduler = RX::TestScheduler.new 

    invoked = 0
    xs = nil

    res = scheduler.configure do 
      RX::Observable.defer do
        invoked += 1

        xs = scheduler.create_cold_observable(
          on_next(100, scheduler.clock),
          on_completed(200)
        )
        xs
      end
    end

    msgs = [
      on_next(300, 200),
      on_completed(400),
    ]
    assert_messages msgs, res.messages    

    assert_equal 1, invoked

    assert_subscriptions [subscribe(200, 400)], xs.subscriptions 
  end
=end

end