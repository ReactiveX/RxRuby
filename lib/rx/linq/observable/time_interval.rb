module RX
  module Observable
    def time_interval(scheduler = DefaultScheduler.instance)
      Observable.defer {
        last = scheduler.now
        self.map {|x|
          now = scheduler.now
          span = now - last
          last = now
          TimeInterval.new(span, x)
        }
      }
    end
  end
end
