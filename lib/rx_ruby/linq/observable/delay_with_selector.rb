module RxRuby
  module Observable
    def delay_with_selector(subscription_delay, delay_duration_selector = nil)
      if Proc === subscription_delay
        selector = subscription_delay
      else
        sub_delay = subscription_delay
        selector = delay_duration_selector
      end

      AnonymousObservable.new do |observer|
        delays = CompositeSubscription.new
        at_end = false
        done = lambda {
          if at_end && delays.length == 0
            observer.on_completed
          end
        }
        subscription = SerialSubscription.new
        start = lambda {|*_|
          subscription.subscription = subscribe(
            lambda {|x|
              begin
                delay = selector.call(x)
              rescue => error
                observer.on_error error
                return
              end
              d = SingleAssignmentSubscription.new
              delays.push(d)
              d.subscription = delay.subscribe(
                lambda {|_|
                  observer.on_next x
                  delays.delete(d)
                  done.call
                },
                observer.method(:on_error),
                lambda {
                  observer.on_next x
                  delays.delete(d)
                  done.call
                })
            },
            observer.method(:on_error),
            lambda {
              at_end = true
              subscription.dispose
              done.call
            })
        }
        
        if !sub_delay
          start.call
        else
          subscription.subscription = sub_delay.subscribe(
            start,
            observer.method(:on_error),
            start)
        end
        CompositeSubscription.new [subscription, delays]
      end
    end
  end
end
