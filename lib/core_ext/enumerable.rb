module Enumerable
  def subscribe(observer, scheduler = RX::Scheduler.immediate)
    begin
      self.each do |e|
        scheduler.schedule do
          observer.on_next(e)
        end
      end
    rescue Exception => ex
      observer.on_error(ex)
      return
    end
    
    observer.on_completed
  end
  
  def to_observable(scheduler = RX::Scheduler.immediate)
    RX::AnonymousObservable.new do |observer|
      self.subscribe(observer, scheduler)
    end
  end
end
