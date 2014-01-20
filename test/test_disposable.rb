# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestDisposable < MiniTest::Unit::TestCase

	def test_disposable_create
		d = RX::Disposable.create lambda { }
		refute_nil d
	end

	def test_create_dispose
		disposed = false
		d = RX::Disposable.create lambda { disposed = true }
		refute disposed

		d.dispose
		assert disposed
	end

	def test_empty
		d = RX::Disposable.empty
		refute_nil d
		d.dispose
	end

end