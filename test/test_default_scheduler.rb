# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'minitest/autorun'
require 'rx'

class TestDefaultScheduler < MiniTest::Unit::TestCase

    def test_now
        s = RX::DefaultScheduler.instance
        assert (s.now - Time.new < 1)
    end

end