module Rx
  module Observable
    def delay(due_time, scheduler = DefaultScheduler.instance)
      if Time === due_time
        delay_date(due_time, scheduler)
      else
        delay_time_span(due_time, scheduler)
      end
    end

    private

    def delay_time_span(due_time, scheduler)
      AnonymousObservable.new do |observer|
        active = false
        cancelable = SerialSubscription.new
        exception = nil
        q = []
        running = false
        subscription = materialize.timestamp(scheduler).subscribe do |notification|
          if notification[:value].on_error?
            q = []
            q.push notification
            exception = notification[:value].error
            should_run = !running
          else
            q.push({ value: notification[:value], timestamp: notification[:timestamp] + due_time })
            should_run = !active
            active = true
          end

          if should_run
            if exception != nil
              observer.on_error exception
            else
              d = SingleAssignmentSubscription.new
              cancelable.subscription = d

              d.subscription = scheduler.schedule_recursive_relative(due_time, lambda {|this|
                return if exception != nil

                running = true
                begin
                  result = nil
                  if q.length > 0 && q[0][:timestamp] - scheduler.now <= 0
                    result = q.shift[:value]
                  end
                  if result != nil
                    result.accept observer
                  end
                end while result != nil

                should_recurse = false
                recurse_due_time = 0
                if q.length > 0
                  should_recurse = true
                  recurse_due_time = [0, q[0][:timestamp] - scheduler.now].max
                else
                  active = false
                end
                e = exception
                running = false
                if e != nil
                  observer.on_error e
                elsif should_recurse
                  this.call recurse_due_time
                end
              })
            end
          end
        end

        CompositeSubscription.new [subscription, cancelable]
      end
    end

    def delay_date(due_time, scheduler)
      delay_time_span(due_time - scheduler.now, scheduler)
    end
  end
end
