# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'
require 'rx_ruby/concurrency/helpers/historical_virtual_scheduler_helper'

class TestHistoricalScheduler < Minitest::Test
  include HistoricalVirtualSchedulerTestHelper

  def setup
    @start     = Time.at(1000)
    @scheduler = RxRuby::HistoricalScheduler.new(@start)
  end

  def test_initialization
    assert_equal(Time.at(1000), @scheduler.now)
    assert_equal(Time.at(0), RxRuby::HistoricalScheduler.new.now)
  end
end
