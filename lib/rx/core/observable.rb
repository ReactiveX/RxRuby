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
      rescue => e
        raise e unless auto_detach_observer.fail e
      end

      RX::Subscription.empty
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