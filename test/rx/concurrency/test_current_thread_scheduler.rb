# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'
require 'rx/concurrency/helpers/immediate_local_scheduler_helper'


class TestCurrentThreadScheduler < Minitest::Test
  include ImmediateLocalSchedulerTestHelper

  def setup
    @scheduler = RX::CurrentThreadScheduler.instance
  end

  def test_schedule_required
    assert_equal(true, RX::CurrentThreadScheduler.schedule_required?)
  end

  def test_schedule
    ran = false
    @scheduler.schedule -> { ran = true }

    assert_equal(true, ran)
  end

  def test_schedule_runs_in_current_thead
    id = Thread.current.object_id
    @scheduler.schedule -> { assert_equal(id, Thread.current.object_id) }
  end

  def test_schedule_error_raises
    assert_raises(StandardError) do
      @scheduler.schedule -> { raise StandardError }
    end
  end

  def test_schedule_nested
    ran = false
    @scheduler.schedule -> do
      @scheduler.schedule -> { ran = true }
    end

    assert_equal(true, ran)
  end
end
