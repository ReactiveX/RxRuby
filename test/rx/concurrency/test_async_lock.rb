# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class TestAsyncLock < Minitest::Test
  def setup
    @lock = RX::AsyncLock.new
  end

  def test_simple_wait
    called = false
    @lock.wait { called = true }
    assert_equal(true, called)
  end

  def test_parallel_wait
    state = [false, false]
    sync  = [Queue.new, Queue.new]

    thread1 = Thread.new do
      sync[0].pop
      @lock.wait do
        sync[1].push 1
        sync[0].pop
        state[0] = true
      end
      state.each { |s| assert_equal(true, s) }
    end

    thread2 = Thread.new do
      sync[1].pop
      @lock.wait do
        assert_equal(thread1, Thread.current)
        state[1] = true
      end
      state.each { |s| assert_equal(false, s) }
      sync[0].push 1
    end

    sync[0].push 1
    [thread1, thread2].each(&:join)
  end

  def test_clear
    @lock.clear
    called = false
    @lock.wait { called = true }
    assert_equal(false, called)
  end

  def test_exceptions_bubble_up_and_fault
    assert_raises(StandardError) { @lock.wait { raise StandardError } }
    assert_equal(true, @lock.send(:instance_variable_get, :@has_faulted))
    assert_equal([], @lock.send(:instance_variable_get, :@queue))
  end
end
