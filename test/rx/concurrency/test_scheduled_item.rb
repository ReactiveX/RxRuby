# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class DummyScheduler
end

class TestScheduledItem < Minitest::Test

  def setup
    @state = []
    @item  = RX::ScheduledItem.new(DummyScheduler.new, @state, 5) do |_, state|
      state << 1
    end
  end

  def test_cancel
    assert_equal(false, @item.cancelled?)
    @item.cancel
    assert_equal(true, @item.cancelled?)
  end

  def test_invocation
    less = RX::ScheduledItem.new(DummyScheduler.new, @state, 0)
    more = RX::ScheduledItem.new(DummyScheduler.new, @state, 10)
    same = RX::ScheduledItem.new(DummyScheduler.new, @state, 5)

    assert(less < @item)
    assert(more > @item)
    assert_equal(same, @item)
  end

  def test_invoke
    @item.invoke
    assert_equal([1], @state)
  end

  def test_invoke_raises_on_subsequent_calls
    @item.invoke
    assert_raises(RuntimeError) { @item.invoke }
  end

  def test_cancel
    assert_equal(false, @item.cancelled?)
    @item.cancel
    assert_equal(true, @item.cancelled?)
    @item.invoke
    assert_equal([], @state)
  end
end
