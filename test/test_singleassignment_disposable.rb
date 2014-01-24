# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestSingleAssignmentDisposable < MiniTest::Unit::TestCase

    def test_disposable_null
        d = RX::SingleAssignmentDisposable.new
        d.disposable = nil

        assert_nil d.disposable
    end

    def test_dispose_after_set
        disposed = false

        d = RX::SingleAssignmentDisposable.new
        dd = RX::Disposable.create { disposed = true }
        d.disposable = dd

        assert_same dd, d.disposable

        refute disposed

        d.dispose

        assert disposed

        d.dispose

        assert disposed
        assert d.disposed?
    end

    def test_dispose_before_set
        disposed = false

        d = RX::SingleAssignmentDisposable.new
        dd = RX::Disposable.create { disposed = true }

        refute disposed
        d.dispose
        refute disposed
        assert d.disposed?

        d.disposable = dd
        assert disposed
        assert d.disposable.nil?
        d.dispose #should be noop

        assert disposed
    end

    def test_dispose_multiple_times
        d = RX::SingleAssignmentDisposable.new
        d.disposable = RX::Disposable.empty

        assert_raises(Exception) { d.disposable = RX::Disposable.empty }
    end

end