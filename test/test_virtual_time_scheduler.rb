# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'minitest/autorun'
require 'rx'

class VirtualSchedulerTestScheduler < RX::VirtualTimeScheduler
  def initialize(clock = '')
    super(clock)
  end

  def add(absolute, relative)
    absolute = '' if absolute.nil?
    absolute + relative
  end

  # Converts the absolute time value to a Time value.
  def to_time(absolute)
    absolute = '' if absolute.nil?
    Time.at(absolute.length)
  end

  # Converts the time span value to a relative time value.
  def to_relative(time_span)
    (time_span % 65535)[0].ord
  end  
end

class TestVirtualTimeScheduler < MiniTest::Unit::TestCase

  def test_now
    s = VirtualSchedulerTestScheduler.new
    assert (s.now - Time.now < 1)
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
end