module RxRuby
  class << Observable
    private
    def observable_timer_time_span_and_period(due_time, period, scheduler)
      if due_time == period
        AnonymousObservable.new do |observer|
          scheduler.schedule_periodic_with_state(0, period,
            lambda {|count|
              observer.on_next(count)
              count + 1
            })
        end
      else
        Observable.defer {
          observable_timer_date_and_period(scheduler.now() + due_time, period, scheduler)
        }
      end
    end
  end
end
