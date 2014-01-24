# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestSerialDisposable < MiniTest::Unit::TestCase

    def test_ctor
        d = RX::SerialDisposable.new
        assert_nil d.disposable
    end

    def test_replace_before_dispose
        disp1 = false
        disp2 = false

        m = RX::SerialDisposable.new
        d1 = RX::Disposable.create { disp1 = true }
        m.disposable = d1
        assert_same d1, m.disposable
        refute disp1

        d2 = RX::Disposable.create { disp2 = true }
        m.disposable = d2
        assert_same d2, m.disposable
        assert disp1
        refute disp2
    end

    def test_replace_after_dispose
        disp1 = false
        disp2 = false

        m = RX::SerialDisposable.new
        m.dispose
        assert m.disposed?

        d1 = RX::Disposable.create { disp1 = true }
        m.disposable = d1
        assert_nil m.disposable
        assert disp1

        d2 = RX::Disposable.create { disp2 = true }
        m.disposable = d2
        assert_nil m.disposable
        assert disp2
    end

    def test_dispose
        disp = false

        m = RX::SerialDisposable.new
        d = RX::Disposable.create { disp = true }
        m.disposable = d
        assert_same d, m.disposable
        refute disp

        m.dispose
        assert m.disposed?
        assert disp
    end

end