# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'minitest/autorun'
require 'rx'

class TestCompositeDisposable < MiniTest::Unit::TestCase

    def test_include
        d1 = RX::Disposable.create  { }
        d2 = RX::Disposable.create  { }

        g = RX::CompositeDisposable.new([d1, d2])

        assert_equal 2, g.length
        assert g.include? d1
        assert g.include? d2
    end

    def test_to_a
        d1 = RX::Disposable.create  { }
        d2 = RX::Disposable.create  { }

        ds = [d1, d2]
        g = RX::CompositeDisposable.new([d1, d2])

        assert_equal 2, g.length

        x = g.to_a
        x.each_with_index do |item, index|
            assert_equal ds[index], item
        end
    end

    def test_push
        d1 = RX::Disposable.create  { }
        d2 = RX::Disposable.create  { }
        g = RX::CompositeDisposable.new([d1])

        assert_equal 1, g.length
        assert g.include? d1

        g.push d2

        assert_equal 2, g.length
        assert g.include? d2        
    end

    def test_push_after_dispose
        disp1 = false
        disp2 = false

        d1 = RX::Disposable.create  { disp1 = true }
        d2 = RX::Disposable.create  { disp2 = true }
        g = RX::CompositeDisposable.new [d1]
        assert_equal 1, g.length

        g.dispose
        assert disp1
        assert_equal 0, g.length

        g.push d2
        assert disp2
        assert_equal 0, g.length

        assert g.disposed?
    end

    def test_remove
        disp1 = false
        disp2 = false

        d1 = RX::Disposable.create  { disp1 = true }
        d2 = RX::Disposable.create  { disp2 = true }
        g = RX::CompositeDisposable.new [d1, d2]

        assert_equal 2, g.length
        assert g.include? d1
        assert g.include? d2

        refute_nil g.delete d1
        assert_equal 1, g.length
        refute g.include? d1
        assert g.include? d2
        assert disp1

        refute_nil g.delete d2
        refute g.include? d1
        refute g.include? d2
        assert disp2

        disp3 = false
        d3 = RX::Disposable.create  { disp3 = true }
        assert_nil g.delete d3
        refute disp3
    end

    def test_clear
        disp1 = false
        disp2 = false

        d1 = RX::Disposable.create  { disp1 = true }
        d2 = RX::Disposable.create  { disp2 = true }
        g = RX::CompositeDisposable.new [d1, d2]
        assert_equal 2, g.length

        g.clear
        assert disp1
        assert disp2
        assert_equal 0, g.length

        disp3 = false
        d3 = RX::Disposable.create  { disp3 = true }
        g.push d3
        refute disp3
        assert_equal 1, g.length
    end
end