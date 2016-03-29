# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'
require 'rx/concurrency/helpers/immediate_local_scheduler_helper'

class TestLocalcheduler < Minitest::Test
  include ImmediateLocalSchedulerTestHelper

  def setup
    @scheduler = Rx::LocalScheduler.new
  end
end
