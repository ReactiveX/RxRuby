# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class PeriodicTestClass
  include RxRuby::PeriodicScheduler
end

class TestPeriodicScheduler < Minitest::Test
  def setup
    @scheduler = PeriodicTestClass.new
  end

  def test_periodic_with_state
    state = []
    task  = ->(x) { x << 1 }

    subscription = @scheduler.schedule_periodic_with_state(state, 0.01, task)
    sleep 0.025
    subscription.unsubscribe
    assert_equal(state.length, 2)
  end

  def test_periodic_with_state_exceptions
    assert_raises(RuntimeError) do
      @scheduler.schedule_periodic_with_state([], 0.01, nil)
    end

    assert_raises(RuntimeError) do
      @scheduler.schedule_periodic_with_state([], -1, ->{})
    end
  end

  def test_periodic
    state = []
    task  = ->() { state << 1 }

    subscription = @scheduler.schedule_periodic(0.01, task)
    sleep 0.025
    subscription.unsubscribe
    assert_equal(state.length, 2)
  end

  def test_periodic_exceptions
    assert_raises(RuntimeError) do
      @scheduler.schedule_periodic(0.01, nil)
    end

    assert_raises(RuntimeError) do
      @scheduler.schedule_periodic(-1, ->{})
    end
  end
end
