# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

module ImmediateLocalSchedulerTestHelper
  def test_now
    assert_equal(Time.now.to_i, @scheduler.now.to_i)
  end

  def test_schedule_with_state
    state = []
    task  = ->(_, s) { s << 1 }
    @scheduler.schedule_with_state(state, task)

    assert_equal([1], state)
  end

  def test_schedule_with_state_simple_absolute
    state = []
    task  = ->(_, s) { s << 1 }
    @scheduler.schedule_absolute_with_state(state, Time.now, task)

    assert_equal([1], state)
  end

  def test_schedule_recursive_absolute_with_state_simple
    state = []
    inner = ->(_, s) { s << 1 }
    outer = ->(s, x) { s.schedule_absolute_with_state(x, Time.now, inner) }
    @scheduler.schedule_absolute_with_state(state, Time.now, outer)

    assert_equal([1], state)
  end

  def test_schedule_with_state_simple_relative
    state = []
    task  = ->(_, s) { s << 1 }
    @scheduler.schedule_relative_with_state(state, 0, task)

    assert_equal([1], state)
  end 

  def test_schedule_recursive_relative_with_state_simple
    state = []
    inner = ->(_, s) { s << 1 }
    outer = ->(sched, s) { sched.schedule_relative_with_state(s, 1, inner) }
    @scheduler.schedule_relative_with_state(state, 1, outer)

    assert_equal([1], state)
  end 
end
