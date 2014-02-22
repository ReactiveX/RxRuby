# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestAsyncLock < MiniTest::Unit::TestCase

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

    thread1 = Thread.new do
      lock.wait do
        sleep 0.01
        called1 = true
      end
      assert called1
      assert called2
    end

    thread2 = Thread.new do
      lock.wait do
        sleep 0.05
        called2 = true
      end
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
