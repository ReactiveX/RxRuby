# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class TestPriorityQueue < Minitest::Test

  def test_simple_push_and_shift
    queue = RX::PriorityQueue.new
    queue.push 400

    assert_equal 400, queue.shift
    assert !queue.shift
  end

  def test_shift_with_priority
    queue = RX::PriorityQueue.new
    queue.push 400
    queue.push 300
    queue.push 500

    assert_equal 300, queue.shift
    assert_equal 400, queue.shift
    assert_equal 500, queue.shift
  end

  def test_delete
    queue = RX::PriorityQueue.new
    [1, 4, 5, 2, 3].each {|it| queue.push it }

    assert !queue.delete(404)
    assert queue.delete(3)
    assert_equal 1, queue.shift
    assert_equal 2, queue.shift
    assert_equal 4, queue.shift
    assert_equal 5, queue.shift
  end

  def test_push_thread_safety
    queue = RX::PriorityQueue.new
    5.times.map {
      Thread.new do
        100.times do |i|
          queue.push i
        end
      end
    }.each(&:join)
    assert_equal 500, queue.length
  end

  def test_shift_thread_safety
    queue = RX::PriorityQueue.new
    500.times {|i| queue.push i }

    5.times.map {
      Thread.new do
        100.times do |i|
          queue.shift
        end
      end
    }.each(&:join)
    assert_equal 0, queue.length
  end

  def test_delete_same_item
    queue = RX::PriorityQueue.new
    10.times { queue.push 42 }
    queue.delete 42
    assert_equal 9, queue.length
  end

end
