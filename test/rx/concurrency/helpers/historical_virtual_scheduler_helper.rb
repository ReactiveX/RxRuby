# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module HistoricalVirtualSchedulerTestHelper

  # Scheduler state

  def test_disabled_by_default
    assert_equal(false, @scheduler.enabled?)
  end

  def test_disabled_once_out_of_tasks
    @scheduler.start
    assert_equal(false, @scheduler.enabled?)
  end

  def test_enabled_while_running
    @scheduler.schedule ->() { assert_equal(true, @scheduler.enabled?) }
    @scheduler.start
  end

  def test_stop
    @scheduler.schedule ->() { @scheduler.stop }
    @scheduler.schedule ->() { flunk "Should be stopped" }
    @scheduler.start

    assert_equal(false, @scheduler.enabled?)
  end

  def test_now
    assert_equal(@start, @scheduler.now)
  end

  def test_clock
    assert_equal @start, @scheduler.clock
  end

  # Relative Scheduling

  def test_relative_with_state
    state = []
    task  = ->(_, s) { s.push 1 }
    @scheduler.schedule_at_relative_with_state(state, 2, task)
    @scheduler.start

    assert_equal([1], state)
    assert_equal(@start + 2, @scheduler.now)
  end

  def test_relative
    ran  = false
    task = ->() { ran = true }
    @scheduler.schedule_at_relative(2, task)
    @scheduler.start

    assert_equal(true, ran)
    assert_equal(@start + 2, @scheduler.now)
  end

  # Absolute Scheduling

  def test_absolute_with_state
    state = []
    time  = @start + 2
    task  = ->(_, s) { s.push 1 }
    @scheduler.schedule_at_absolute_with_state(state, time, task)
    @scheduler.start

    assert_equal([1], state)
    assert_equal(time, @scheduler.now)
  end

  def test_absolute
    ran   = false
    time  = @start + 2
    task  = ->() { ran = true }
    @scheduler.schedule_at_absolute(time, task)
    @scheduler.start

    assert_equal(true, ran)
    assert_equal(time, @scheduler.now)
  end

  # Time manipulation

  def test_advance
    ran     = false
    task    = ->() { ran = true }
    failure = ->() { flunk "Should never reach." }

    @scheduler.schedule_at_absolute(@start + 10, task)
    @scheduler.schedule_at_absolute(@start + 11, failure)
    @scheduler.advance_to(@start + 10)

    assert_equal(true, ran)
    assert_equal(@start + 10, @scheduler.now)
  end

  def test_advance_raises_if_running
    task = ->() do
      assert_raises(RuntimeError) { @scheduler.advance_to(@start + 10) }
    end

    @scheduler.schedule task
    @scheduler.start
  end

  def test_advance_by
    ran     = false
    task    = ->() { ran = true }
    failure = ->() { flunk "Should never reach." }

    @scheduler.schedule_at_relative(10, task)
    @scheduler.schedule_at_relative(11, failure)
    @scheduler.advance_by(10)

    assert_equal(true, ran)
    assert_equal(@start + 10, @scheduler.now)
  end

  def test_advance_raises_if_out_of_range
    assert_raises(RuntimeError) { @scheduler.advance_by(-10) }
  end

  def test_sleep
    failure = ->() { flunk "Should not run." }
    @scheduler.schedule_at_relative(10, failure)
    @scheduler.sleep(20)

    assert_equal(@start + 20, @scheduler.now)
  end

  def test_sleep_raises_if_out_of_range
    assert_raises(RuntimeError) { @scheduler.sleep(-10) }
  end
end
