module RxRuby::Observable
  def self.interval(period, scheduler = RxRuby::DefaultScheduler.instance)
    observable_timer_time_span_and_period(period, period, scheduler)
  end
end
