module Enumerable
  def subscribe(observer, scheduler = RxRuby::ImmediateScheduler.instance)
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
  
  def to_observable(scheduler = RxRuby::ImmediateScheduler.instance)
    RxRuby::AnonymousObservable.new do |observer|
      self.subscribe(observer, scheduler)
    end
  end
end
