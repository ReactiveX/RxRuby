# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

module RX
  class AbstractObserver
    def initialize
      @stopped = false
    end
    
    def on_completed
      unless @stopped
        @stopped = true
        self.completed
      end
    end
    
    def on_error(exception)
      # TODO: Error checking
      
      unless @stopped
        @stopped = true
        self.error(exception)
      end
    end
    
    def on_next(value)
      unless @stopped
        self.next(value)
      end
    end
    
    def stop
      @stopped = true
    end
  end
end
