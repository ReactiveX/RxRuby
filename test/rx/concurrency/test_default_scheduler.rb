# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

# DefaultScheduler creates new threads in which to run scheduled tasks; a short
# sleep is necessary to allow the thread scheduler to yield to the other
# threads.
class TestDefaultScheduler < Minitest::Test

  def setup
    @scheduler = RX::DefaultScheduler.instance
  end

  def test_schedule_with_state
    state = []
    task  = ->(_, s) { s << 1 }
    d = @scheduler.schedule_with_state(state, task)
    sleep 0.001

    assert_equal([1], state)
  end

  def test_schedule_relative_with_state
    state = []
    task  = ->(_, s) { s << 1 }
    d = @scheduler.schedule_relative_with_state(state, 0.05, task)
    sleep 0.1

    assert_equal([1], state)
  end

  def test_default_schedule_runs_in_its_own_thread
    id = Thread.current.object_id
    @scheduler.schedule -> { refute_equal(id, Thread.current.object_id) }
    sleep 0.001
  end

  def test_schedule_action_cancel
    task = -> { flunk "This should not run." }
    subscription = @scheduler.schedule_relative(0.05, task)
    subscription.unsubscribe
    sleep 0.1
  end
end
