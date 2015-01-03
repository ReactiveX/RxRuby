module RX
  module Observable
    def add_ref(r)
      AnonymousObservable.new do |observer|
        CompositeSubscription.new [r.subscription, self.subscribe(observer)]
      end
    end
  end
end
