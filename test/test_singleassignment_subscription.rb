# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestSingleAssignmentSubscription < MiniTest::Unit::TestCase

    def test_subscription_null
        d = RX::SingleAssignmentSubscription.new
        d.subscription = nil

        assert_nil d.subscription
    end

    def test_dispose_after_set
        unsubscribed = false

        d = RX::SingleAssignmentSubscription.new
        dd = RX::Subscription.create { unsubscribed = true }
        d.subscription = dd

        assert_same dd, d.subscription

        refute unsubscribed

        d.unsubscribe

        assert unsubscribed

        d.unsubscribe

        assert unsubscribed
        assert d.unsubscribed?
    end

    def test_dispose_before_set
        unsubscribed = false

        d = RX::SingleAssignmentSubscription.new
        dd = RX::Subscription.create { unsubscribed = true }

        refute unsubscribed
        d.unsubscribe
        refute unsubscribed
        assert d.unsubscribed?

        d.subscription = dd
        assert unsubscribed
        assert d.subscription.nil?
        d.unsubscribe #should be noop

        assert unsubscribed
    end

    def test_dispose_multiple_times
        d = RX::SingleAssignmentSubscription.new
        d.subscription = RX::Subscription.empty

        assert_raises(Exception) { d.subscription = RX::Subscription.empty }
    end

end