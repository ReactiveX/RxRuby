# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestSubscription < MiniTest::Unit::TestCase

  def test_disposable_create
    d = RX::Subscription.create { }
    refute_nil d
  end

  def test_create_dispose
    unsubscribed = false
    d = RX::Subscription.create { unsubscribed = true }
    refute unsubscribed

    d.unsubscribe
    assert unsubscribed
  end

  def test_empty
    d = RX::Subscription.empty
    refute_nil d
    d.unsubscribe
  end

end