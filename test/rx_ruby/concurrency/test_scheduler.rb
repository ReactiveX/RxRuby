# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'test_helper'

class MyScheduler
  include RxRuby::Scheduler

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

  def setup
    @scheduler = MyScheduler.new
  end

  def test_now
    assert_equal(Time.now.to_i, RxRuby::Scheduler.now.to_i)
  end

  def test_schedule_absolute
    due  = Time.now + 1
    ran  = false
    task = ->() { ran = true }

    @scheduler.check { |a, s, t| assert_equal(1, t.to_i) }
    @scheduler.schedule_absolute(due, task)

    assert_equal(true, ran)
    assert_equal(1, @scheduler.wait_cycles.to_i)
  end

  def test_schedule_non_recursive
    ran = false
    @scheduler.schedule_recursive(->(a) { ran = true })
    assert_equal(true, ran)
  end

  def test_schedule_recursive
    calls = 0
    task = ->(a) do
      calls += 1
      a.call if calls < 10
    end
    @scheduler.schedule_recursive(task)

    assert_equal(10, calls)
  end

  def test_schedule_recursive_absolute_non_recursive
    now = Time.now
    ran = false

    @scheduler.check { |a, s, t| assert_equal(0, t.to_i) }
    @scheduler.schedule_recursive_absolute(now, ->(a) { ran = true })
    assert_equal(true, ran)
    assert_equal(0, @scheduler.wait_cycles.to_i)
  end

  def test_schedule_recursive_absolute_recursive
    now   = Time.now
    calls = 0
    task  = ->(a) do
      calls += 1
      a.call(now) if calls < 10
    end

    @scheduler.check { |a, s, t| assert_equal(0, t.to_i) }
    @scheduler.schedule_recursive_absolute(now, task)

    assert_equal(0, @scheduler.wait_cycles.to_i)
    assert_equal(10, calls)
  end

  def test_schedule_recursive_relative_non_recursive
    now  = Time.now
    ran  = false
    task = ->(a) { ran = true }

    @scheduler.check { |a, s, t| assert_equal(0, t.to_i) }
    @scheduler.schedule_recursive_relative(0, task)

    assert_equal(true, ran)
    assert_equal(0, @scheduler.wait_cycles)
  end

  def test_schedule_recursive_relative_recursive
    now   = Time.now
    calls = 0
    task  = ->(a) do
      calls += 1
      a.call(calls) if calls < 10
    end

    @scheduler.check { |a, s, t| assert_operator(t, :<, 10) }

    @scheduler.schedule_recursive_relative(0, task)
    assert_equal(45, @scheduler.wait_cycles)
    assert_equal(10, calls)
  end

end
