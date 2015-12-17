module RxRuby
  class << Observable
    def timer(due_time, period_or_scheduler = DefaultScheduler.instance, scheduler = DefaultScheduler.instance)
      case period_or_scheduler
      when Numeric
        period = period_or_scheduler
      when Scheduler
        scheduler = period_or_scheduler
      end

      if Time === due_time
        if period.nil?
          observable_timer_date(due_time, scheduler)
        else
          observable_timer_date_and_period(due_time, period, scheduler)
        end
      else
        if period.nil?
          observable_timer_time_span(due_time, scheduler)
        else
          observable_timer_time_span_and_period(due_time, period, scheduler)
        end
      end
    end
  end
end
