require 'rx'
require 'support/matchers'
require 'support/stubbed_observer'

describe Enumerable do
  before {
    @observer = StubbedObserver.new
  }

  pending '#to_observable' do
    let(:range_to_observable) { (1..10).to_observable }

    before { range_to_observable.subscribe(@observer) }

    specify { @observer.next.should == 9 }
    specify { @observer.should have_no_error }
    specify { @observer.should be_completed }
  end
end