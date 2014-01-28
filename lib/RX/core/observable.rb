# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/current_thread_scheduler'
require 'rx/concurrency/immediate_scheduler'
require 'rx/core/auto_detach_observer'
require 'rx/subscriptions/subscription'

module RX

  module Observable

    # Subscribes the given observer to the observable sequence.
    def subscribe(observer)
      raise 'observer cannot be nil' unless observer

      auto_detach_observer = AutoDetachObserver.new observer

      if RX::CurrentThreadScheduler.schedule_required?
        RX::CurrentThreadScheduler.instance.schedule_with_state auto_detach_observer, method(:schedule_subscribe)
      else
        begin
          auto_detach_observer.subscription = self.subscribe_core auto_detach_observer
        rescue => e  
          raise e unless auto_detach_observer.fail e
        end
      end

      auto_detach_observer
    end

    # Subscribes the given block to the on_next action of the observable sequence.
    def subscribe_on_next
      obs = RX::Observer.configure do |o|
        o.on_next yield
      end

      self.subscribe obs
    end

    def schedule_subscribe(scheduler, auto_detach_observer)
      begin
        auto_detach_observer.subscription = self.subscribe_core auto_detach_observer
      rescue Exception => e
        raise e unless auto_detach_observer.fail e
      end

      RX::Subscription.empty
    end

    # Creation Operators

    # Creates an observable sequence from a specified subscribe method implementation.
    def self.create(&subscribe)
      AnonymousObservable.new do |obs|
        a = subscribe.call obs
        a = RX::Subscription.empty unless a
        a
      end
    end

    # Returns an empty observable sequence, using the specified scheduler to send out the single OnCompleted message.
    def self.empty(scheduler = RX::ImmediateScheduler.instance)
      AnonymousObservable.new do |obs|
        scheduler.schedule lambda {
          obs.on_completed
        }
      end
    end

    # Returns a non-terminating observable sequence, which can be used to denote an infinite duration (e.g. when using reactive joins).
    def self.never
      AnonymousObservable.new do |obs|

      end
    end

    # Returns an observable sequence that contains a single element.
    def self.just(value, scheduler = RX::ImmediateScheduler.instance)
      AnonymousObservable.new do |obs|
        scheduler.schedule lambda {
          obs.on_next value
          obs.on_completed
        }
      end
    end

  end

  class AnonymousObservable

    include Observable

    def initialize(&subscribe)
      @subscribe = subscribe
    end

    def subscribe_core(obs)
      res = @subscribe.call obs
      return res.nil? ? RX::Subscription.empty : res
    end

  end

end