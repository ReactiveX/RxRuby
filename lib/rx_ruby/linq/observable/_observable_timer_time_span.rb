module RxRuby
  class << Observable
    private
    def observable_timer_time_span(due_time, scheduler)
      AnonymousObservable.new do |observer|
        scheduler.schedule_relative(Scheduler.normalize(due_time),
          lambda {
            observer.on_next(0)
            observer.on_completed
          })
      end
    end
  end
end
