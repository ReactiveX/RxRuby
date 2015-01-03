module RX
  module Observable
    def multicast(subject_or_subject_selector, selector = nil)
      if Proc === subject_or_subject_selector
        AnonymousObservable.new do |observer|
          connectable = self.multicast(subject_or_subject_selector.call)
          CompositeSubscription.new [selector.call(connectable).subscribe(observer), self]
        end
      else
        ConnectableObservable.new(self, subject_or_subject_selector)
      end
    end
  end
end
