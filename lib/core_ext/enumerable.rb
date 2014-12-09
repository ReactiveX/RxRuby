module Enumerable
  def subscribe(observer, scheduler = RX::ImmediateScheduler.instance)
    begin
      self.each do |e|
        scheduler.schedule do
          observer.on_next(e)
        end
      end
    rescue => ex
      observer.on_error(ex)
      return
    end
    
    observer.on_completed
  end
  
  def to_observable(scheduler = RX::ImmediateScheduler.instance)
    RX::AnonymousObservable.new do |observer|
      self.subscribe(observer, scheduler)
    end
  end
end
