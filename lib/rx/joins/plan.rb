module RX
  class Plan
    def initialize(expression, selector)
      @expression = expression
      @selector = selector
    end

    def activate(external_subscriptions, observer, deactivate)
      join_observers = []
      @expression.patterns.each {|pat|
        join_observers.push plan_create_observer(external_subscriptions, pat, observer.method(:on_error))
      }

      active_plan = ActivePlan.new(join_observers, lambda {|*args|
        begin
          result = @selector.call(*args)
        rescue => e
          observer.on_error e
        end
        observer.on_next result
      },
      lambda {
        join_observers.each {|v|
          v.remove_active_plan(active_plan)
        }
        deactivate.call(active_plan)
      })
      join_observers.each {|v|
        v.add_active_plan(active_plan)
      }
      return active_plan
    end

    def plan_create_observer(external_subscriptions, observable, on_error)
      entry = external_subscriptions[observable]
      if !entry
        observer = JoinObserver.new(observable, on_error)
        external_subscriptions[observable] = observer
        return observer
      end
      entry
    end
  end
end
