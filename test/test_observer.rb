# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'minitest/autorun'
require 'rx'

class TestObserver < MiniTest::Unit::TestCase

  def test_configure_on_next
    next_called = false
    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end
    end

    res.on_next 42
    assert next_called
    res.on_completed
  end

  def test_configure_on_next_has_error
    ex = RuntimeError.new
    e1 = nil

    next_called = false
    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end
    end

    res.on_next 42
    assert next_called

    begin
      res.on_error ex
      fluke
    rescue => e
      e1 = e
    end

    assert_same ex, e1
  end

  def test_configure_on_next_on_completed
    next_called = false
    completed = false

    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute completed

    res.on_completed
    assert completed
  end

  def test_configure_on_next_on_completed_has_error
    ex = RuntimeError.new
    e1 = nil

    next_called = false
    completed = false

    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute completed

    begin
     res.on_error ex
     flunk
    rescue => e
      e1 = e
    end

    assert_same ex, e1
    refute completed       
  end

  def test_configure_on_next_on_error
    ex = RuntimeError.new
    next_called = false
    error = false

    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end
    end

    res.on_next 42
    assert next_called
    refute error

    res.on_error ex
    assert error
  end

  def test_configure_on_next_on_error_hit_completed
    ex = RuntimeError.new
    next_called = false
    error = false

    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end
    end

    res.on_next 42
    assert next_called
    refute error

    res.on_completed
    refute error
  end

  def test_configure_on_next_on_error_on_completed1
    ex = RuntimeError.new
    next_called = false
    error = false
    completed = false

    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute error
    refute completed

    res.on_completed
    assert completed
    refute error
  end

  def test_configure_on_next_on_error_on_completed1
    ex = RuntimeError.new
    next_called = false
    error = false
    completed = false

    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute error
    refute completed

    res.on_completed
    assert completed
    refute error
  end

  def test_configure_on_next_on_error_on_completed2
    ex = RuntimeError.new
    next_called = false
    error = false
    completed = false

    res = RX::Observer.configure do |o|
      o.on_next do |x|
        assert_equal 42, x
        next_called = true
      end

      o.on_error do |err|
        assert_same ex, err
        error = true
      end

      o.on_completed { completed = true }
    end

    res.on_next 42
    assert next_called
    refute error
    refute completed

    res.on_error ex
    assert error
    refute completed
  end

end
