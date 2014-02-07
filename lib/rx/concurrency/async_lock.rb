# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'

module RX
  # Asynchronous lock.
  class AsyncLock

    def initialize
      @queue = []
      @is_acquired = false
      @has_faulted = false
      @gate = Mutex.new
    end

    def wait(&action)
      is_owner = false
      @gate.synchronize do
        unless @has_faulted
          @queue.push action
          is_owner = !@is_acquired
          @is_acquired = true
        end
      end

      if is_owner
        while true
          work = nil
          @gate.synchronize do
            if @queue.length > 0
              work = @queue.shift
            else
              @is_acquired = false
            end
          end

          break unless @is_acquired

          begin
            work.call
          rescue => e
            @gate.synchronize do
              @queue = []
              @has_faulted = true
            end

            raise e
          end
        end
      end
    end

    # Clears the work items in the queue and drops further work being queued.
    def clear
      @gate.synchronize do 
        @queue = []
        @has_faulted = true
      end
    end

  end
end
