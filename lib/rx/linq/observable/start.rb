module RX
  class <<Observable
    def start(func, context, scheduler = DefaultScheduler.instance)
      Observable.to_async(func, context, scheduler).call
    end
  end
end
