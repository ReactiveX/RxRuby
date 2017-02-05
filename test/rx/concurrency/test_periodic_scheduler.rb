# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class PeriodicTestClass
  include Rx::PeriodicScheduler
end

def await_array_length(array, expected, interval)
  sleep (expected * interval) * 0.9
  deadline = Time.now + interval * (expected + 1)
  while Time.now < deadline
    break if array.length == expected
    sleep interval / 10
  end
end

class TestPeriodicScheduler < Minitest::Test
  def setup
    @scheduler = PeriodicTestClass.new
  end

  INTERVAL = 0.05

  def test_periodic_with_state
    state = []
    task  = ->(x) { x << 1 }

    subscription = @scheduler.schedule_periodic_with_state(state, INTERVAL, task)
    await_array_length(state, 2, INTERVAL)
    subscription.unsubscribe
    assert_equal(state.length, 2)
  end

  def test_periodic_with_state_exceptions
    assert_raises(RuntimeError) do
      @scheduler.schedule_periodic_with_state([], INTERVAL, nil)
    end

    assert_raises(RuntimeError) do
      @scheduler.schedule_periodic_with_state([], -1, ->{})
    end
  end

  def test_periodic
    state = []
    task  = ->() { state << 1 }

    subscription = @scheduler.schedule_periodic(INTERVAL, task)
    await_array_length(state, 2, INTERVAL)
    subscription.unsubscribe
    assert_equal(state.length, 2)
  end

  def test_periodic_exceptions
    assert_raises(RuntimeError) do
      @scheduler.schedule_periodic(INTERVAL, nil)
    end

    assert_raises(RuntimeError) do
      @scheduler.schedule_periodic(-1, ->{})
    end
  end
end
