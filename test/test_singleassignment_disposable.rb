require 'minitest/autorun'
require 'rx'

class TestSingleAssignmentDisposable < MiniTest::Unit::TestCase

    def test_disposable_null
        d = RX::SingleAssignmentDisposable.new
        d.disposable = nil

        assert d.disposable.nil?
    end

    def test_dispose_after_set
        disposed = false

        d = RX::SingleAssignmentDisposable.new
        dd = RX::Disposable.new { disposed = true }
        d.disposable = dd

        assert_same dd, d.disposable

        assert_equal false, disposed

        d.dispose

        assert_equal true, disposed

        d.dispose

        assert_equal true, disposed
        assert_equal true, d.disposed?
    end

end