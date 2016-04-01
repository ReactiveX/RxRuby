module Enumerable
  def subscribe(observer, scheduler = Rx::ImmediateScheduler.instance)
    begin
      self.each do |e|
        scheduler.schedule lambda {
          observer.on_next(e)
        }
      end
    rescue => ex
      observer.on_error(ex)
      return
    end
    
    observer.on_completed
  end
  
  def to_observable(scheduler = Rx::ImmediateScheduler.instance)
    Rx::AnonymousObservable.new do |observer|
      self.subscribe(observer, scheduler)
    end
  end
end
