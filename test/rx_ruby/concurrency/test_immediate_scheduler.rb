# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'
require 'rx_ruby/concurrency/helpers/immediate_local_scheduler_helper'

class TestImmediateScheduler < Minitest::Test
  include ImmediateLocalSchedulerTestHelper

  def setup
    @scheduler = RxRuby::ImmediateScheduler.instance
  end

  def test_now
    assert_equal(Time.now.to_i, @scheduler.now.to_i)
  end

  def test_immediate_schedule
    ran = false
    @scheduler.schedule -> { ran = true }
    assert_equal(true, ran)
  end

  def test_immediate_schedule_runs_in_current_thread
    id = Thread.current.object_id
    @scheduler.schedule -> { assert_equal(id, Thread.current.object_id) }
  end

  def test_schedule_error_raises
    task = -> do
      raise(StandardError)
      flunk "Should not be reached."
    end

    assert_raises(StandardError) { @scheduler.schedule(task) }
  end

  def test_schedule_with_state_simple
    state = []
    task = ->(_, s) { s << 1 }
    @scheduler.schedule_with_state(state, task)

    assert_equal([1], state)
  end

  def test_schedule_recursive_with_state_simple
    state = []
    inner = ->(_, s) { s << 1 }
    outer = ->(sched, s) { sched.schedule_with_state(s, inner) }
    @scheduler.schedule_with_state(state, outer)

    assert_equal([1], state)
  end
end
