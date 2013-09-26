# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

module RX
  class CompositeDisposable
    
    def initialize(disposables = [])
      @disposables = disposables
      @disposed = false
      @gate = Mutex.new
    end
    
    def dispose
      currentDisposables = nil
      @gate.synchronize do
        unless @disposed
          @disposed = true
          currentDisposables = @disposables
          @disposables = []
        end
      end
      unless currentDisposables.nil?
        currentDisposables.each {|disposable| disposable.dispose}
      end
    end
    
    def add(disposable)
      shouldDispose = false
      @gate.synchronize do
        shouldDispose = @disposed
        unless @disposed
          @disposables.push(disposable)
        end
      end
      if shouldDispose
        disposable.dispose
      end
    end
    
    def clear
      currentDisposables = nil
      @gate.synchronize do
        currentDisposables = @disposables
        @disposables = []
      end
      currentDisposables.each {|disposable| disposable.dispose}
    end
    
    def count 
      @disposables.length
    end
    
    def remove(disposable)
      should_dispose = false
      @gate.synchronize do
        should_dispose = @disposables.delete(disposable).dispose.nil?
      end
      if should_dispose
        disposable.dispose
      end
      should_dispose
    end
  end
end
