# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'minitest/autorun'
require 'rx'

class TestImmediateScheduler < MiniTest::Unit::TestCase
	def test_now
		s = RX::ImmediateScheduler.instance
		assert (s.now - Time.new < 1)
	end

	def test_immediate_schedule
		s = RX::ImmediateScheduler.instance
		id = Thread.current.object_id
		ran = false
		s.schedule lambda { 
			assert_equal id, Thread.current.object_id
			ran = true
		}

		assert ran
	end

	def test_schedule_error
		s = RX::ImmediateScheduler.instance
		e = Exception.new

		begin
			s.schedule lambda {
				raise e
				assert false
			}
		rescue Exception => ex
			assert_same e, ex
		end
	end
end
