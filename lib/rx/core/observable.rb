# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/current_thread_scheduler'
require 'rx/concurrency/immediate_scheduler'
require 'rx/core/observer'
require 'rx/core/auto_detach_observer'
require 'rx/subscriptions/subscription'

module RX

  module Observable

    # Subscribes the given observer to the observable sequence.
    def subscribe(observer = Observer.configure)

      auto_detach_observer = AutoDetachObserver.new observer

      if CurrentThreadScheduler.schedule_required?
        CurrentThreadScheduler.instance.schedule_with_state auto_detach_observer, method(:schedule_subscribe)
      else
        begin
          auto_detach_observer.subscription = subscribe_core auto_detach_observer
        rescue => e  
          raise e unless auto_detach_observer.fail e
        end
      end

      auto_detach_observer
    end

    # Subscribes the given block to the on_next action of the observable sequence.
    def subscribe_on_next(&block)
      obs = Observer.configure do |o|
        o.on_next &block
      end

      subscribe obs
    end

    # Subscribes the given block to the on_error action of the observable sequence.
    def subscribe_on_error(&block)
      obs = Observer.configure do |o|
        o.on_error &block
      end

      subscribe obs
    end    

    # Subscribes the given block to the on_completed action of the observable sequence.
    def subscribe_on_completed(&block)
      obs = Observer.configure do |o|
        o.on_completed &block
      end

      subscribe obs
    end        

    private

    def schedule_subscribe(scheduler, auto_detach_observer)
      begin
        auto_detach_observer.subscription = subscribe_core auto_detach_observer
      rescue => e
        raise e unless auto_detach_observer.fail e
      end

      Subscription.empty
    end

  end

  class AnonymousObservable

    include Observable

    def initialize(&subscribe)
      @subscribe = subscribe
    end

    protected

    def subscribe_core(obs)
      @subscribe.call(obs) || Subscription.empty
    end

  end

end