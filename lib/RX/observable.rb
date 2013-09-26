# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

require 'rx/auto_detach_observer'
require 'rx/auto_detach_disposable'
require 'rx/disposable'
require 'rx/mutable_disposable'
require 'rx/scheduler'

module RX
  module Observable

    def initialize(&subscribe)
      @subscribe_action = subscribe
    end

    def subscribe(observer)
      auto_detach_observer = observer.is_a?(RX::AutoDetachObserver) ? observer : RX::AutoDetachObserver.new(observer)
      subscription = RX::AutoDetachDisposable.new(auto_detach_observer)
      auto_detach_observer.add(subscription)

      #TODO: ensure trampoline
      subscription.set(@subscribe_action.call(auto_detach_observer))
      
      subscription
    end
    
    def self.create_with_disposable(&subscribe)
    
    end
    
    def self.never
      RX::AnonymousObservable.new do |observer|
        RX::EmptyObservable.new
      end
    end
    
    def self.empty(scheduler = RX::Scheduler.immediate)
      RX::AnonymousObservable.new do |observer|
        scheduler.schedule do
          observer.on_completed
        end
      end
    end 
    
    def self.return(value, scheduler = RX::Scheduler.immediate)
      
      RX::AnonymousObservable.new do |observer|
        scheduler.schedule do
          observer.on_next(value)
          observer.on_completed
        end
      end
    end
    
    def self.throw(exception, scheduler = RX::Scheduler.immediate)
      RX::AnonymousObservable.new do |observer|
        scheduler.schedule do
          observer.on_error(exception)
        end
      end
    end 
    
    def self.generate(initial_state, condition, result_selector, iterate, scheduler = RX::Scheduler.immediate)
      RX::AnonymousObservable.new do | observer|
        state = initial_state
        first = true
        
        scheduler.schedule_recursive do |this|
          hasResult = false
          result = nil
          begin
            if first
              first = false
            else
              state = iterate.call(state)
            end
            hasResult = condition.call(state)
            if hasResult
              result = result_selector.call(state)
            end
          rescue => err
            observer.on_error(err)
            return
          end
          if hasResult
            observer.on_next(result)
            this.call
          else
            observer.on_completed
          end
        end
      end
    end
    
    
    def self.range(start, length, scheduler = RX::Scheduler.immediate)
      max = start + length - 1
      RX::Observable.generate(start, lambda {|x| x <= max}, lambda {|x| x}, lambda {|x| x + 1 }, scheduler)
    end 
    
    def merge
      RX::AnonymousObservable.new do |observer|
        gate = Mutex.new
        stopped = false
        group = RX::CompositeDisposable.new
        outer_subscription = RX::MutableDisposable.new
        group.add(outer_subscription) 

        outer_subscription.replace(self.subscribe(RX::Observer.new do |o|
          o.with_on_next do |inner_source|
            inner_subscription = RX::MutableDisposable.new
            group.add(inner_subscription)
            inner_subscription.replace(inner_source.subscribe(RX::Observer.new do |inner_o|
              inner_o.with_on_next do |inner_value|
                gate.synchronize do
                  observer.on_next(inner_value)
                end
              end
              
              inner_o.with_on_error do |inner_error|
                gate.synchronize do
                  observer.on_error(inner_error)
                end
              end
              
              inner_o.with_on_completed do
                group.remove(inner_subscription)
                if stopped && group.count == 1
                  gate.synchronize do
                    observer.on_completed
                  end
                end             
              end
            end))
          end

          o.with_on_error do |exception|
            gate.synchronize do
              observer.on_error(exception)
            end
          end
          
          o.with_on_completed do
            stopped = true
            if group.count == 1
              gate.synchronize do
                observer.on_completed
              end
            end         
          end
        end))
        gate
      end
    end
    
    def where(&predicate)
      RX::AnonymousObservable.new do |observer|
        on_next_action = proc do |next_value| 
          shouldFire = false
          begin
            shouldFire = predicate.call(next_value)
          rescue => err
            observer.on_error(err)
            return
          end
          if shouldFire
            observer.on_next(next_value) 
          end
        end
        
        obs = RX::Observer.new do |o|
          o.with_on_next do |next_value| 
            shouldFire = false
            begin
              shouldFire = predicate.call(next_value)
            rescue => err
              observer.on_error(err)
              return
            end
            if shouldFire
              observer.on_next(next_value) 
            end
          end
          
          o.with_on_error do |exception|
            observer.on_error(exception)
          end
          
          o.with_on_completed do 
            observer.on_completed
          end
        end

        self.subscribe(obs)
      end
    end
    
    def select(&selector)
      RX::AnonymousObservable.new do |observer|
        obs = RX::Observer.new do |o|
          o.with_on_next do |next_value| 
            value = nil
            begin
              value = selector.call(next_value)
            rescue => err
              observer.on_error(err)
              return
            end
            observer.on_next(value) 
          end
          
          o.with_on_error do |exception|
            observer.on_error(exception)
          end
          
          o.with_on_completed do 
            observer.on_completed
          end
        end
        self.subscribe(obs)
      end
    end
    
    def select_many(&selector)
      self.select(&selector).merge
    end

    def finally(&finally_action)
      RX::AnonymousObservable.new do |observer|
        subscription = self.subscribe(observer)
        RX::Disposable.new do
          begin
            subscription.dispose
          ensure
            finally_action.call
          end
        end
      end
    end
  end

  class AnonymousObservable
    include RX::Observable
  end
end
