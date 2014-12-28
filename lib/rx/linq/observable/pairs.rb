module RX
  class <<Observable
    def pairs(obj, scheduler = CurrentThreadScheduler.instance)
      AnonymousObservable.new {|observer|
        idx = 0
        keys = obj.keys
        len = keys.length
        scheduler.schedule_recursive lambda {|this|
          if idx < len
            key = keys[idx]
            idx += 1
            observer.on_next [key, obj[key]]
            this.call
          else
            observer.on_completed
          end
        }
      }
    end
  end
end
