# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class TestSerialSubscription < Minitest::Test

    def test_ctor
        d = RX::SerialSubscription.new
        assert_nil d.subscription
    end

    def test_replace_before_dispose
        disp1 = false
        disp2 = false

        m = RX::SerialSubscription.new
        d1 = RX::Subscription.create { disp1 = true }
        m.subscription = d1
        assert_same d1, m.subscription
        refute disp1

        d2 = RX::Subscription.create { disp2 = true }
        m.subscription = d2
        assert_same d2, m.subscription
        assert disp1
        refute disp2
    end

    def test_replace_after_dispose
        disp1 = false
        disp2 = false

        m = RX::SerialSubscription.new
        m.unsubscribe
        assert m.unsubscribed?

        d1 = RX::Subscription.create { disp1 = true }
        m.subscription = d1
        assert_nil m.subscription
        assert disp1

        d2 = RX::Subscription.create { disp2 = true }
        m.subscription = d2
        assert_nil m.subscription
        assert disp2
    end

    def test_dispose
        disp = false

        m = RX::SerialSubscription.new
        d = RX::Subscription.create { disp = true }
        m.subscription = d
        assert_same d, m.subscription
        refute disp

        m.unsubscribe
        assert m.unsubscribed?
        assert disp
    end

end
