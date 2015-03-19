# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'test_helper'

class MyScheduler
  include RX::Scheduler

  attr_reader :now
  attr_accessor :wait_cycles

  def initialize(now = Time.now)
    @now = now
    @wait_cycles = 0
    @check = nil
  end

  def check(&action)
    @check = action
  end

  def schedule_with_state(state, action)
    action.call self, state
  end

  def schedule_relative_with_state(state, due_time, action)
    @check.call(lambda {|o| action.call(self, o)}, state, due_time)
    @wait_cycles += due_time
    action.call(self, state)
  end

  def schedule_absolute_with_state(state, due_time, action)
    self.schedule_relative_with_state(state, due_time - now, action)
  end
end

class TestBaseScheduler < Minitest::Test

  def test_schedule_non_recursive
    ms = MyScheduler.new
    res = false
    ms.schedule_recursive(lambda {|a| res = true })
    assert res
  end

  def test_schedule_recursive
    ms = MyScheduler.new
    i = 0
    ms.schedule_recursive(lambda {|a|
      i+=1
      a.call if i < 10
    })

    assert_equal 10, i
  end

  def test_schedule_recursive_absolute_non_recursive
    now = Time.now
    ms = MyScheduler.new now
    res = false

    ms.check do |a, s, t|
      assert_equal t, 0
    end

    ms.schedule_recursive_absolute(now, lambda {|a| res = true })
    assert res
    assert_equal 0, ms.wait_cycles
  end

  def test_schedule_recursive_absolute_recursive
    now = Time.now
    i = 0
    ms = MyScheduler.new(now)

    ms.check do |a, s, t|
      assert_equal t, 0
    end

    ms.schedule_recursive_absolute(now, lambda {|a|
      i += 1
      a.call(now) if i < 10
    })

    assert_equal 0, ms.wait_cycles
    assert_equal 10, i    
  end

  def test_schedule_recursive_relative_non_recursive
    now = Time.now
    ms = MyScheduler.new(now)
    res = false

    ms.check do |a, s, t|
      assert_equal t, 0
    end

    ms.schedule_recursive_relative(0, lambda {|a| res = true })

    assert res
    assert_equal 0, ms.wait_cycles
  end

  def test_schedule_recursive_relative_recursive
    now = Time.now
    i = 0
    ms = MyScheduler.new(now)

    ms.check do |a, s, t|
      assert_operator t, :<, 10
    end

    ms.schedule_recursive_relative(0, lambda {|a|
      i += 1
      a.call i if i < 10
    })

    assert_equal 45, ms.wait_cycles
    assert_equal 10, i  
  end

  def test_schedule_state_threading
    lst = []
    RX::ImmediateScheduler.instance.schedule_recursive_with_state(0, lambda {|i, a|
      lst.push(i)
      a.call(i + 1) if i < 9
    })

    assert_equal (0..9).to_a, lst
  end

end
