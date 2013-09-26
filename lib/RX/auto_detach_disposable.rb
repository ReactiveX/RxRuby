# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

module RX
  class AutoDetachDisposable
    def initialize(observer)
      @gate = Mutex.new
      @observer = observer
      @disposed = false
      @disposable = nil
    end
    
    def dispose
      disposable = nil
      @observer.stop
      @gate.synchronize do
        unless @disposed
          @disposed = true
          disposable = @disposable
        end
      end
      
      unless disposable.nil?
        disposable.dispose
      end
    end
    
    def set(disposable)
      flag = false
      @gate.synchronize do
        unless @disposed
          @disposable = disposable
        else
          flag = true
        end
      end
      if flag
        disposable.dispose
      end   
    end
  end
end
