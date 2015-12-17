module RxRuby
  module Observable
    def timestamp(scheduler = DefaultScheduler.instance)
      map do |x|
        { value: x, timestamp: scheduler.now }
      end
    end
  end
end
