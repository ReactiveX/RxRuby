# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'test_helper'

class VirtualSchedulerTestScheduler < RX::VirtualTimeScheduler
  def initialize(clock = '')
    super(clock)
  end

  def add(absolute, relative)
    absolute ||=''
    absolute + relative
  end

  # Converts the absolute time value to a Time value.
  def to_time(absolute)
    absolute ||=''
    Time.at(absolute.length)
  end

  # Converts the time span value to a relative time value.
  def to_relative(time_span)
    (time_span % 65535)[0].ord
  end  
end

class TestVirtualTimeScheduler < Minitest::Test

  def test_now
    s = VirtualSchedulerTestScheduler.new
    assert_operator s.now-Time.now, :<, 1
  end

  def test_schedule_action
    id = Thread.current.object_id
    s = VirtualSchedulerTestScheduler.new
    ran = false

    s.schedule lambda {
      assert id, Thread.current.object_id
      ran = true
    }

    s.start
    assert ran
  end

  def test_schedule_action_error
    err = RuntimeError.new

    begin
      s = VirtualSchedulerTestScheduler.new
      s.schedule lambda { raise err }
      s.start
      flunk 'Should not reach here'
    rescue => e
      assert_equal err, e
    end
  end

  def test_virtual_initial_now
    s = VirtualSchedulerTestScheduler.new 'bar'
    assert_equal 3, s.now.to_i
  end
end
