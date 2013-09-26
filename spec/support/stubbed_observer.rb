require 'rx/observer'

class StubbedObserver < RX::Observer
  attr_reader :next, :error, :completed

  def initialize
    @completed = false
    
    with_on_next { |next_value| @next = next_value }
    with_on_error { |error| @error = error }
    with_on_completed { @completed = true }
  end
end