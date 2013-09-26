# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

module RX
  class BooleanDisposable

    def initialize
      @is_disposed = false
    end
    
    def disposed?
      @is_disposed
    end
    
    def dispose
      @is_disposed = true
    end
  end
end
