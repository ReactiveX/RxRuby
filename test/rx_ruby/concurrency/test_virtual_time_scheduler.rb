# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'
require 'rx_ruby/concurrency/helpers/historical_virtual_scheduler_helper'

class TestVirtualTimeScheduler < Minitest::Test

  include HistoricalVirtualSchedulerTestHelper

  def setup
    @start     = Time.now.to_i
    @scheduler = RxRuby::VirtualTimeScheduler.new(@start)
  end
end
