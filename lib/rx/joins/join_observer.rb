module RX
  class JoinObserver < ObserverBase

    attr_reader :queue
    def initialize(source, on_error)
      super Observer.configure {|o|
        o.on_next {|notification|
          if !@is_disposed
            if notification.on_error?
              @on_error.call(notification.exception)
              next
            end
            @queue.push notification
            @active_plans.dup.each {|v|
              v.match
            }
          end
        }
      }
      @source = source
      @on_error = on_error
      @queue = []
      @active_plans = []
      @subscription = SingleAssignmentSubscription.new
      @is_disposed = false
    end

    def add_active_plan(active_plan)
      @active_plans.push active_plan
    end

    def subscribe
      @subscription.subscription = @source.materialize.subscribe(@config)
    end

    def remove_active_plan(active_plan)
      if idx = @active_plans.index(active_plan)
        @active_plans.delete_at idx
      end
      self.unsubscribe if @active_plans.length == 0
    end

    def unsubscribe
      super
      if !@is_disposed
        @is_disposed = true
        @subscription.unsubscribe
      end
    end
  end
end
