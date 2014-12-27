module RX
  class <<Observable
    def if(condition, then_source, else_source_or_scheduler = nil)
      case else_source_or_scheduler
      when Scheduler
        scheduler = else_source_or_scheduler
        else_source = Observable.empty(scheduler)
      when Observable
        else_source = else_source_or_scheduler
      when nil
        else_source = Observable.empty
      end

      return condition.call ? then_source : else_source
    end
  end
end
