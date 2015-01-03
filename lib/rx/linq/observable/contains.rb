module RX
  module Observable
    def contains(search_element, from_index = 0)
      AnonymousObservable.new do |observer|
        i = 0
        n = from_index
        if n < 0
          observer.on_next false
          observer.on_completed
          return Subscription.empty
        end

        subscribe(
          lambda {|x|
            if i.tap { i += 1 } >= n && x == search_element
              observer.on_next true
              observer.on_completed
            end
          },
          observer.method(:on_error),
          lambda {
            observer.on_next false
            observer.on_completed
          })
      end
    end
  end
end
