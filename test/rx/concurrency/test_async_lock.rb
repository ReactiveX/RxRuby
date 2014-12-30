# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

require 'thread'

class TestAsyncLock < Minitest::Test

  def test_simple_wait
    lock = RX::AsyncLock.new
    called = false
    lock.wait { called = true }
    assert called
  end

  def test_parallel_wait
    lock = RX::AsyncLock.new
    called1 = false
    called2 = false

    q1 = Queue.new
    q2 = Queue.new

    thread1 = Thread.new do
      assert q1.pop == 1
      # 1
      lock.wait do
        q2.push 2
        assert q1.pop == 4
        # 4
        called1 = true
        # 5
      end
      # 8
      assert called1
      assert called2
    end

    thread2 = Thread.new do
      assert q2.pop == 2
      # 2
      lock.wait do
        # 6
        assert Thread.current == thread1
        called2 = true
        # 7
      end
      # 3
      assert !called1
      assert !called2
      q1.push 4
    end

    q1.push 1
    [thread1, thread2].each(&:join)
  end

  def test_clear
    lock = RX::AsyncLock.new
    lock.clear
    called = false
    lock.wait { called = true }
    assert !called
  end
end
