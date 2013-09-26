# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

module RX
  class Observer
    @on_next_action
    @on_error_action
    @on_completed_action

    def initialize
      @on_error_action = lambda {|exception| raise exception }
      @on_completed_action = lambda {}
      yield self if block_given?
    end
    
    def with_on_next(&on_next_action)
      @on_next_action = on_next_action
      self
    end
    
    def with_on_error(&on_error_action)
      @on_error_action = on_error_action
      self
    end
    
    def with_on_completed(&on_completed_action)
      @on_completed_action = on_completed_action
      self
    end
    
    def on_next(value)
      @on_next_action.call(value)
    end
    
    def on_error(exception)
      @on_error_action.call(exception)
    end
    
    def on_completed
      @on_completed_action.call
    end
  end
end
