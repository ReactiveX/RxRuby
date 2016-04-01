module Rx
  module Observable
    def concat_map_observer(on_next, on_error, on_completed)
      AnonymousObservable.new do |observer|
        index = 0

        subscribe(
          lambda {|x|
            begin
              result = on_next.call(x, index)
              index += 1
            rescue => e
              observer.on_error e
              return
            end
            observer.on_next result
          },
          lambda {|err|
            begin
              result = on_error.call(err)
            rescue => e
              observer.on_error e
              return
            end

            observer.on_next result
            observer.on_completed
          },
          lambda {
            begin
              result = on_completed.call
            rescue => e
              observer.on_error e
              return
            end

            observer.on_next result
            observer.on_completed
          })
      end.concat_all
    end
  end
end
