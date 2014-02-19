# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestPriorityQueue < MiniTest::Unit::TestCase

  def test_simple_push_and_shift
    queue = RX::PriorityQueue.new
    queue.push 400

    assert_equal 400, queue.shift
    assert_raises(RuntimeError) { queue.shift }
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

end
