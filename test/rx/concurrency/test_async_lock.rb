# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

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

    # 1
    thread1 = Thread.new do
      lock.wait do
        # 3
        sleep 0.01
        called1 = true
        # 5
      end
      # 8
      assert called1
      assert called2
    end

    # 2
    thread2 = Thread.new do
      Thread.pass  # switch force
      lock.wait do
        # 6
        sleep 0.05
        called2 = true
        # 7
      end
      # 4
      assert !called1
      assert !called2
    end

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
