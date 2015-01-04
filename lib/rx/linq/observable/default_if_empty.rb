module RX
  module Observable
    def default_if_empty(default_value = nil)
      AnonymousObservable.new do |observer|
        found = false
        subscribe(
          lambda {|x|
            found = true
            observer.on_next x
          },
          observer.method(:on_error),
          lambda {
            observer.on_next default_value unless found
            observer.on_completed
          })
      end
    end
  end
end
