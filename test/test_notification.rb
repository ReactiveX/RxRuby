# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestNotification < MiniTest::Unit::TestCase
  include RX::ReactiveTest

  def test_to_observable_empty
    scheduler = RX::TestScheduler.new

    res = scheduler.configure do 
      RX::Notification.create_on_completed.to_observable(scheduler)
    end

    reactive_assert [on_completed(201)], res.messages
  end

  def test_to_observable_just
    scheduler = RX::TestScheduler.new

    res = scheduler.configure do 
      RX::Notification.create_on_next(42).to_observable(scheduler)
    end

    reactive_assert [on_next(201, 42), on_completed(201)], res.messages
  end

  def test_to_observable_raise
    err = RuntimeError.new
    scheduler = RX::TestScheduler.new

    res = scheduler.configure do 
      RX::Notification.create_on_error(err).to_observable(scheduler)
    end

    reactive_assert [on_error(201, err)], res.messages
  end

  def test_notification_equality
    n = RX::Notification.create_on_next(42)
    e = RX::Notification.create_on_error(RuntimeError.new)
    c = RX::Notification.create_on_completed

    n1 = n
    n2 = n
    e1 = e
    e2 = e
    c1 = c
    c2 = c

    assert(n1 == n2)
    assert(e1 == e2)
    assert(c1 == c2) 

    assert(n1.eql? n2)
    assert(e1.eql? e2)
    assert(c1.eql? c2)       
  end

  def test_on_next_intialize
    n = RX::Notification.create_on_next(42)

    assert n.on_next?
    assert n.has_value?
    assert_equal 42, n.value
  end

  def test_on_next_equality
    n1 = RX::Notification.create_on_next(42)
    n2 = RX::Notification.create_on_next(42)
    n3 = RX::Notification.create_on_next(24)
    n4 = RX::Notification.create_on_completed

    assert(n1.eql? n1)
    assert(n1.eql? n2)
    refute(n1.eql? n3)
    refute(n3.eql? n1)
    refute(n1.eql? n4)
    refute(n4.eql? n1)
  end

  def test_on_next_to_s
    n = RX::Notification.create_on_next(42)
    s = n.to_s

    assert (s.include? '42')
    assert (s.include? 'on_next')
  end

  class AcceptObserver
    include RX::Observer

    def initialize
      @config = RX::ObserverConfiguration.new
      yield @config
    end

    def on_next(value)
      @config.on_next(value)
    end

    def on_error(error)
      @config.on_error(error)
    end

    def on_completed
      @config.on_completed
    end
  end

  class CheckOnNextObserver
    attr_reader :value

    include RX::Observer

    def on_next(value)
      @value = value
    end
  end

  def test_on_next_accept
    con = CheckOnNextObserver.new
    n1 = RX::Notification.create_on_next(42)
    n1.accept(con)

    assert_equal 42, con.value
  end

end