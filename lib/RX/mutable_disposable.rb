# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

module RX
  class MutableDisposable

    def initialize
      @current = nil
      @disposed = false
      @gate = Mutex.new
    end
    
    def replace(disposable)
      shouldDispose = false
      @gate.synchronize do
        shouldDispose = @disposed   
        unless shouldDispose
          unless @current.nil?
            @current.dispose
          end
          @current = disposable
        end
      end
      if shouldDispose && !disposable.nil?
        disposable.dispose
      end
    end

    def dispose
      @gate.synchronize do
        unless @disposed
          @disposed = true
          unless @current.nil?
            @current.dispose
            @current = nil
          end
        end
      end
    end
  end
end
