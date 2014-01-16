# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

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
      
      @disposable_action.call if should_dispose
    end
  end
end
