module RX
  module Observable
    def do(observer_or_on_next, on_error_func = nil, on_completed_func = nil)
      if Proc === observer_or_on_next
        on_next_func = observer_or_on_next
      else
        on_next_func = observer_or_on_next.method(:on_next)
        on_error_func = observer_or_on_next.method(:on_error)
        on_completed_func = observer_or_on_next.method(:on_completed)
      end
      AnonymousObservable.new do |observer|
        subscribe(
          lambda {|x|
            begin
              on_next_func.call x
            rescue => e
              observer.on_error e
            end
            observer.on_next x
          },
          lambda {|err|
            begin
              on_error_func && on_error_func.call(x)
            rescue => e
              observer.on_error e
            end
            observer.on_error err
          },
          lambda {
            begin
              on_completed_func && on_completed_func.call
            rescue => e
              observer.on_error e
            end
            observer.on_completed
          })
      end
    end
  end
end
