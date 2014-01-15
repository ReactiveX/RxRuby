# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX
  class CompositeDisposable
    
    include Enumerable

    attr_reader :length

    def initialize(disposables = [])
      @disposables = disposables
      @length = disposables.length
      @disposed = false
      @gate = Mutex.new
    end

    def disposed?
      @disposed
    end

    def each(&block)
      @disposables.each(&block)
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
    
    def push(disposable)
      shouldDispose = false
      
      @gate.synchronize do
        shouldDispose = @disposed
      
        unless @disposed
          @disposables.push(disposable)
          @length += 1
        end
      end
      
      disposable.dispose if should_dispose

      return self
    end
    
    def clear
      currentDisposables = nil
      
      @gate.synchronize do
        currentDisposables = @disposables
        @disposables = []
      
      end
      currentDisposables.each {|disposable| disposable.dispose}
    end
    
    def delete(disposable)
      should_dispose = false
      
      @gate.synchronize do
        should_dispose = @disposables.delete(disposable).dispose.nil?
        @length -= 1 if should_dispose
      end
      
      disposable.dispose if should_dispose

      should_dispose
    end
  end
end
