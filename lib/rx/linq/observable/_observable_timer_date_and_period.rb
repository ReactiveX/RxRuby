module Rx
  class << Observable
    private
    def observable_timer_date_and_period(due_time, period, scheduler)
      AnonymousObservable.new do |observer|
        count = 0
        d = due_time
        p = Scheduler.normalize(period)
        scheduler.schedule_recursive_absolute(d, lambda {|this|
          if p > 0
            now = scheduler.now()
            d = d + p
            d <= now && (d = now + p)
          end
          observer.on_next(count)
          count += 1
          this.call(d)
        })
      end
    end
  end
end
