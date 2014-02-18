# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'minitest/autorun'
require 'rx'

class TestDefaultScheduler < MiniTest::Unit::TestCase

  def test_now
    s = RX::DefaultScheduler.instance
    assert (s.now - Time.new < 1)
  end

  def test_default_schedule
    id = Thread.current.object_id
    s = RX::DefaultScheduler.instance

    s.schedule lambda {
      refute id, Thread.current.object_id
    }
    sleep 1
  end

  def test_default_schedule_due
    id = Thread.current.object_id
    s = RX::DefaultScheduler.instance

    s.schedule_relative 0.2, lambda {
      refute id, Thread.current.object_id
    }
    sleep 1
  end

  def test_schedule_action_cancel
    id = Thread.current.object_id
    s = RX::DefaultScheduler.instance
    set = false
    d = s.schedule_relative 0.2, lambda {
      assert false
    }
    d.unsubscribe
    sleep 0.4
    refute set
  end

  def test_periodic_non_reentrant
    s = RX::DefaultScheduler.instance
    n = 0
    fail = false

    d = s.schedule_periodic_with_state(0, 0.05, lambda {|x| 
      begin
        if n > 1
          n += 1
          fail = true
        end

        sleep 0.1

        return x + 1
      ensure
        n -= 1
      end
    })

    sleep 0.5
    d.unsubscribe
    refute fail
  end

end