# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

require 'rx/abstract_observer'
require 'rx/composite_disposable'

module RX
  class AutoDetachObserver < RX::AbstractObserver
    def initialize(observer)
      @group = RX::CompositeDisposable.new
      @observer = observer
    end
    
    def add(disposable)
      @group.add(disposable)
    end
    
    def completed
      @observer.on_completed
      @group.dispose
    end
    
    def error(exception)
      @observer.on_error(exception)
      @group.dispose
    end
    
    def next(value)
      @observer.on_next(value)
    end
  end
end
