# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'monitor'
require 'thread'
require 'test_helper'

class MyObserver
  include Rx::Observer

  attr_reader :next, :error, :completed

  def initialize
    @next = false
    @error = false
    @completed = false
  end

  def on_next(value)
    @next = value
  end

  def on_error(error)
    @error = error
  end

  def on_completed
    @completed = true
  end

end

class TestObserver < Minitest::Test

  def test_from_notifier_notification_on_next
    i = 0
    obs = Rx::Observer.from_notifier do |n|  
      assert_equal i, 0
      i += 1
      assert n.on_next?
      assert_equal 42, n.value
      assert n.has_value?
    end

    obs.on_next 42
  end

  def test_from_notifier_notification_on_error
    err = RuntimeError.new
    i = 0
    obs = Rx::Observer.from_notifier do |n|
      assert_equal i, 0
      i += 1
      assert n.on_error?
      assert_same n.error, err
      refute n.has_value?
    end

    obs.on_error err
  end

  def test_from_notifier_notification_on_completed
    i = 0
    obs = Rx::Observer.from_notifier do |n|
      assert_equal i, 0
      i += 1
      assert n.on_completed?
      refute n.has_value?      
    end

    obs.on_completed
  end

  def test_to_notifier_forwards
    obsn = MyObserver.new
    obsn.to_notifier.call(Rx::Notification.create_on_next 42)
    assert_equal 42, obsn.next

    err = RuntimeError.new
    obse = MyObserver.new
    obse.to_notifier.call(Rx::Notification.create_on_error err)
    assert_same err, obse.error

    obsc = MyObserver.new
    obsc.to_notifier.call(Rx::Notification.create_on_completed)
    assert obsc.completed
  end

  def test_as_observer_hides
    obs = MyObserver.new
    res = obs.as_observer

    refute_same obs, res
  end

  def test_as_observer_forwards
    obsn = MyObserver.new
    obsn.as_observer.on_next 42
    assert_equal 42, obsn.next

    err = RuntimeError.new
    obse = MyObserver.new
    obse.as_observer.on_error err
    assert_same err, obse.error

    obsc = MyObserver.new
    obsc.as_observer.on_completed
    assert obsc.completed    
  end

  def test_configure_on_next
    next_called = false
    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end
    end

    res.on_next 42
    assert next_called
    res.on_completed
  end

  def test_configure_on_next_has_error
    ex = RuntimeError.new
    e1 = nil

    next_called = false
    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end
    end

    res.on_next 42
    assert next_called

    begin
      res.on_error ex
      fluke
    rescue => e
      e1 = e
    end

    assert_same ex, e1
  end

  def test_configure_on_next_on_completed
    next_called = false
    completed = false

    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute completed

    res.on_completed
    assert completed
  end

  def test_configure_on_next_on_completed_has_error
    ex = RuntimeError.new
    e1 = nil

    next_called = false
    completed = false

    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute completed

    begin
     res.on_error ex
     flunk
    rescue => e
      e1 = e
    end

    assert_same ex, e1
    refute completed       
  end

  def test_configure_on_next_on_error
    ex = RuntimeError.new
    next_called = false
    error = false

    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end
    end

    res.on_next 42
    assert next_called
    refute error

    res.on_error ex
    assert error
  end

  def test_configure_on_next_on_error_hit_completed
    ex = RuntimeError.new
    next_called = false
    error = false

    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end
    end

    res.on_next 42
    assert next_called
    refute error

    res.on_completed
    refute error
  end

  def test_configure_on_next_on_error_on_completed1
    ex = RuntimeError.new
    next_called = false
    error = false
    completed = false

    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute error
    refute completed

    res.on_completed
    assert completed
    refute error
  end

  def test_configure_on_next_on_error_on_completed1
    ex = RuntimeError.new
    next_called = false
    error = false
    completed = false

    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute error
    refute completed

    res.on_completed
    assert completed
    refute error
  end

  def test_configure_on_next_on_error_on_completed2
    ex = RuntimeError.new
    next_called = false
    error = false
    completed = false

    res = Rx::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute error
    refute completed

    res.on_error ex
    assert error
    refute completed
  end

  def test_checked_already_terminated_completed
    m = 0
    n = 0

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| m += 1 }
      obs.on_error {|err| flunk }
      obs.on_completed { n += 1 }
    end

    o = o.checked

    o.on_next 1
    o.on_next 2
    o.on_completed

    assert_raises(RuntimeError) { o.on_completed }
    assert_raises(RuntimeError) { o.on_error RuntimeError.new }

    assert_equal 2, m
    assert_equal 1, n
  end

  def test_checked_already_terminated_error
    m = 0
    n = 0

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| m += 1 }
      obs.on_error {|err| n += 1 }
      obs.on_completed { flunk }
    end

    o = o.checked

    o.on_next 1
    o.on_next 2
    o.on_error RuntimeError.new

    assert_raises(RuntimeError) { o.on_completed }
    assert_raises(RuntimeError) { o.on_error RuntimeError.new }

    assert_equal 2, m
    assert_equal 1, n
  end

  def test_checked_reentrant_next
    n = 0

    o = Rx::Observer.configure do |obs|
      obs.on_next do |x|
        n += 1

        assert_raises(RuntimeError) { o.on_next 9 }
        assert_raises(RuntimeError) { o.on_error RuntimeError.new }
        assert_raises(RuntimeError) { o.on_completed }
      end

      obs.on_error {|err| flunk }
      obs.on_completed { flunk }
    end

    o = o.checked
    o.on_next 1

    assert_equal 1, n
  end

  def test_checked_reentrant_error
    n = 0

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| flunk }

      obs.on_error do |err|
        n += 1

        assert_raises(RuntimeError) { o.on_next 9 }
        assert_raises(RuntimeError) { o.on_error RuntimeError.new }
        assert_raises(RuntimeError) { o.on_completed }
      end

      obs.on_completed { flunk }
    end

    o = o.checked
    o.on_error RuntimeError.new

    assert_equal 1, n
  end

  def test_checked_reentrant_completed
    n = 0

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| flunk }
      obs.on_error {|x| flunk }

      obs.on_completed do
        n += 1

        assert_raises(RuntimeError) { o.on_next 9 }
        assert_raises(RuntimeError) { o.on_error RuntimeError.new }
        assert_raises(RuntimeError) { o.on_completed }
      end
    end

    o = o.checked
    o.on_completed

    assert_equal 1, n
  end  

  def test_synchronize_monitor_reentrant_1
    res = false
    in_one = false

    s = nil
    o = Rx::Observer.configure do |obs|
      obs.on_next do |x|
        if x == 1
          in_one = true
          s.on_next 2
          in_one = false
        elsif x == 2
          res = in_one
        end
      end
    end

    s = Rx::Observer.allow_reentrancy o
    s.on_next 1
    assert res
  end

  def test_synchronize_monitor_reentrant_2
    res = false
    in_one = false

    s = nil
    o = Rx::Observer.configure do |obs|
      obs.on_next do |x|
        if x == 1
          in_one = true
          s.on_next 2
          in_one = false
        elsif x == 2
          res = in_one
        end
      end
    end

    s = Rx::Observer.allow_reentrancy o, Monitor.new
    s.on_next 1
    assert res
  end  

  def test_synchronize_monitor_non_reentrant_1
    res = false
    in_one = false

    s = nil
    o = Rx::Observer.configure do |obs|
      obs.on_next do |x|
        if x == 1
          in_one = true
          s.on_next 2
          in_one = false
        elsif x == 2
          res = !in_one
        end
      end
    end

    s = Rx::Observer.prevent_reentrancy o
    s.on_next 1
    assert res
  end

  def test_synchronize_monitor_non_reentrant_2
    res = false
    in_one = false

    s = nil
    o = Rx::Observer.configure do |obs|
      obs.on_next do |x|
        if x == 1
          in_one = true
          s.on_next 2
          in_one = false
        elsif x == 2
          res = !in_one
        end
      end
    end

    s = Rx::Observer.prevent_reentrancy o, Rx::AsyncLock.new
    s.on_next 1
    assert res
  end

  def test_synchronize_monitor_non_reentrant_next
    res = false
    s = nil

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| res = x == 1 }
      obs.on_error {|err| flunk }
      obs.on_completed { flunk }
    end

    s = Rx::Observer.prevent_reentrancy o
    s.on_next 1

    assert res
  end

  def test_synchronize_monitor_non_reentrant_error
    res = nil
    e = RuntimeError.new
    s = nil

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| flunk }
      obs.on_error {|err| res = err }
      obs.on_completed { flunk }
    end

    s = Rx::Observer.prevent_reentrancy o
    s.on_error e

    assert_same e, res
  end

  def test_synchronize_monitor_non_reentrant_completed
    res = false
    s = nil

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| flunk }
      obs.on_error {|err| flunk }
      obs.on_completed { res = true }
    end

    s = Rx::Observer.prevent_reentrancy o
    s.on_completed

    assert res
  end

  def test_notify_on_success
    c = 0
    num = 100

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| c += 1 }
      obs.on_error {|err| flunk }
      obs.on_completed { }
    end

    s = Rx::ImmediateScheduler.instance
    n = o.notify_on(s)

    for i in 0..num
      n.on_next i
    end

    n.on_completed

    assert_equal c, 101
  end

  def test_notify_on_error
    c = 0
    num = 100
    err = RuntimeError.new

    o = Rx::Observer.configure do |obs|
      obs.on_next {|x| c += 1 }
      obs.on_error {|e| assert_same err, e }
      obs.on_completed { flunk }
    end

    s = Rx::ImmediateScheduler.instance
    n = o.notify_on(s)

    for i in 0..num
      n.on_next i
    end

    n.on_error err
  end  

end
