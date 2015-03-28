# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'
require 'rx/concurrency/historical_virtual_helper'

class TestVirtualTimeScheduler < Minitest::Test

  include ScheduleTestHelper

  def setup
    @start     = Time.now.to_i
    @scheduler = RX::VirtualTimeScheduler.new(@start)
  end
end
