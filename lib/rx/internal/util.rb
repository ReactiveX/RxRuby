module RX
  module Observable
    private

    def add_ref(xs, r)
      AnonymousObservable.new do |observer|
        CompositeSubscription.new [r.subscription, xs.subscribe(observer)]
      end
    end
  end
end
