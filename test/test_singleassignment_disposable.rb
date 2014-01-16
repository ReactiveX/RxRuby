require 'minitest/autorun'
require 'rx'

class TestSingleAssignmentDisposable < Minitest::Test

	def test_disposable_null
		d = RX::SingleAssignmentDisposable.new
		d.disposable = nil

		assert d.disposable.nil?
	end

end