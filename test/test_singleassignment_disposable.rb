require 'minitest/autorun'
require 'rx'

class TestSingleAssignmentDisposable < MiniTest::Unit::TestCase

    def test_disposable_null
        d = RX::SingleAssignmentDisposable.new
        d.disposable = nil

        assert_equal true, d.disposable.nil?
    end

    def test_dispose_after_set
        disposed = false

        d = RX::SingleAssignmentDisposable.new
        dd = RX::Disposable.create { disposed = true }
        d.disposable = dd

        assert_same dd, d.disposable

        assert_equal false, disposed

        d.dispose

        assert_equal true, disposed

        d.dispose

        assert_equal true, disposed
        assert_equal true, d.disposed?
    end

    def test_dispose_before_set
        disposed = false

        d = RX::SingleAssignmentDisposable.new
        dd = RX::Disposable.create { disposed = true }

        assert_equal false, disposed
        d.dispose
        assert_equal false, disposed
        assert_equal true, d.disposed?

        d.disposable = dd
        assert_equal true, disposed
        d.disposable.dispose

        d.dispose
        assert_equal true, disposed
    end

    def test_dispose_multiple_times
        d = RX::SingleAssignmentDisposable.new
        d.disposable = RX::Disposable.empty

        assert_raises(Exception) { d.disposable = RX::SingleAssignmentDisposable.new }
    end

end