module Rx
  class ConnectableObservable < AnonymousObservable
    def initialize(source, subject)
      @has_subscription = false
      @subscription = nil
      @source_observable = source.as_observable
      @subject = subject

      super(&subject.method(:subscribe))
    end

    def connect
      unless @has_subscription
        @has_subscription = true
        @subscription = CompositeSubscription.new [@source_observable.subscribe(@subject), Subscription.create { @has_subscription = false }]
      end
      @subscription
    end

    def ref_count
      count = 0
      AnonymousObservable.new do |observer|
        count += 1
        should_connect = true if count == 1
        connectable_subscription = self.connect if should_connect
        Subscription.create {
          @subscription.unsubscribe
          count -= 1
          connectable_subscription.unsubscribe if count == 0
        }
      end
    end
  end
end
