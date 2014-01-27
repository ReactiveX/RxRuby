# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'minitest/autorun'
require 'rx'

module RX
    # Extend to include ensure trampoline
    class CurrentThreadScheduler
        def ensure_trampoline(action)
            if self.schedule_required?
                self.schedule(action);
            else
                action.call
            end
        end
    end
end

class TestCurrentThreadScheduler < MiniTest::Unit::TestCase

    def test_now
        s = RX::CurrentThreadScheduler.instance
        assert (s.now - Time.now < 1)
    end

    def test_schedule
        id = Thread.current.object_id
        s = RX::CurrentThreadScheduler.instance
        ran = false

        s.schedule lambda {
            assert_equal id, Thread.current.object_id
            ran = true
        }

        assert ran
    end

    def test_schedule_error
        s = RX::CurrentThreadScheduler.instance
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

    def test_schedule_nested
        s = RX::CurrentThreadScheduler.instance
        id = Thread.current.object_id
        ran = false

        s.schedule lambda {
            assert_equal id, Thread.current.object_id
            s.schedule lambda { ran = true }
        }

        assert ran
    end

    def test_schedule_nested_relative
        s = RX::CurrentThreadScheduler.instance
        id = Thread.current.object_id
        ran = false

        s.schedule lambda {
            assert_equal id, Thread.current.object_id
            s.schedule_relative 1, lambda { ran = true }
        }

        assert ran
    end

    def test_ensure_trampoline
        s = RX::CurrentThreadScheduler.instance
        ran1 = false
        ran2 = false

        s.ensure_trampoline lambda {
            s.schedule lambda { ran1 = true }
            s.schedule lambda { ran2 = true }
        }

        assert ran1
        assert ran2
    end

    def test_ensure_trampoline_nested
        s = RX::CurrentThreadScheduler.instance
        ran1 = false
        ran2 = false

        s.ensure_trampoline lambda {
            s.ensure_trampoline lambda { ran1 = true }
            s.ensure_trampoline lambda { ran2 = true }
        }

        assert ran1
        assert ran2
    end

    def test_ensure_trampoline_and_cancel
        s = RX::CurrentThreadScheduler.instance
        ran1 = false
        ran2 = false

        s.ensure_trampoline lambda {
            ran1 = true
            d = s.schedule lambda { ran2 = true }
            d.unsubscribe
        }

        assert ran1
        refute ran2
    end

    def test_ensure_trampoline_and_cancel_timed
        s = RX::CurrentThreadScheduler.instance
        ran1 = false
        ran2 = false

        s.ensure_trampoline lambda {
            ran1 = true
            d = s.schedule_relative 1, lambda { ran2 = true }
            d.unsubscribe
        }

        assert ran1
        refute ran2
    end     

end