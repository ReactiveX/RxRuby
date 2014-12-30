module RX
  class <<Observable
    def while(condition, source)
      enum = Enumerator.new {|y|
        while condition.call
          y << source
        end
      }
      scheduler = ImmediateScheduler.instance

      is_disposed = false
      subscription = SerialSubscription.new

      AnonymousObservable.new do |observer|
        cancelable = scheduler.schedule_recursive lambda {|this|
          return if is_disposed

          begin
            current_value = enum.next
          rescue StopIteration => e
            observer.on_completed
            return
          rescue => e
            observer.on_error e
            return
          end

          d = SingleAssignmentSubscription.new
          subscription.subscription = d
          d.subscription = current_value.subscribe(
            observer.method(:on_next),
            observer.method(:on_error),
            lambda { this.call }
          )
        }

        CompositeSubscription.new [subscription, cancelable, Subscription.create { is_disposed = true }]
      end
    end
  end
end
