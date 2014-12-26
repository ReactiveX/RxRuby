module RX
  class <<Observable
    def from(iterable, map_fn = nil, scheduler = CurrentThreadScheduler.instance)
      it = iterable.to_enum
      AnonymousObservable.new {|observer|
        i = 0
        scheduler.schedule_recursive lambda {|this|
          begin
            result = it.next
          rescue StopIteration => e
            observer.on_completed
            return
          rescue => e
            observer.on_error e
            return
          end

          if Proc === map_fn
            begin
              result = map_fn.call(result, i)
            rescue => e
              observer.on_error e
              return
            end
          end

          observer.on_next result
          i += 1
          this.call
        }
      }
    end
  end
end
