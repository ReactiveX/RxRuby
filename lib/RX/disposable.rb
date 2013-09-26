# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

module RX
  class Disposable
    
    def initialize(&disposable_action)
      @disposable_action = disposable_action
      @gate = Mutex.new
      @disposed = false
    end
    
    def dispose
      should_dispose = false
      @gate.synchronize do
        should_dispose = !@disposed
      end
      if should_dispose
        @disposable_action.call
      end
    end
  end
end
