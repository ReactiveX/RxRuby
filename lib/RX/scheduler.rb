# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

require 'rx/empty_disposable'

module RX
  class Scheduler

    def initialize(schedule_action, schedule_with_time_action, now_action)
      @schedule_action = schedule_action
      @schedule_with_time_action = schedule_with_time_action
      @now_action = now_action  
    end

    @@immediate_scheduler = RX::Scheduler.new( 
      lambda do |action|
        action.call
        RX::EmptyDisposable.new
      end,
      lambda do |action, due_time|
        sleep(due_time)
        action.call
        RX::EmptyDisposable.new
      end,
      lambda { Time.now } )
    
    @@new_thread_scheduler = RX::Scheduler.new( 
      lambda do |action|
        t = Thread.new(&action)
        RX::Disposable.new do
          t.kill
        end
      end,
      lambda do |action, due_time|
        t = Thread.new do
          sleep(due_time)
          action.call
        end
        RX::Disposable.new do
          t.kill
        end
      end,
      lambda { Time.now })
    
    def schedule(&action)
      @schedule_action.call(action)
    end
    
    def schedule_with_time(dueTime, &action)
      @schedule_with_time_action.call(action, dueTime)
    end
    
    def now
      @now_action.call
    end
    
    def self.immediate    
      @@immediate_scheduler
    end
    
    def self.new_thread
      @@new_thread_scheduler
    end
    def schedule_recursive(&action)
      group = RX::CompositeDisposable.new
      
      recursiveAction = proc do
        action.call(proc do
          isAdded = false
          isDone = false
          d = self.schedule do
            recursiveAction.call
            if isAdded
              group.remove(d)
            else
              isDone = true
            end         
          end
          unless isDone
            group.add(d)
            isAdded = true
          end
        end)
      end
      group.add(self.schedule(&recursiveAction))
      group
    end
  end 
end
