module RX
  class <<Observable
    def to_async(func, context = nil, scheduler = DefaultScheduler.instance)
      lambda() {|*args|
        subject = AsyncSubject.new

        scheduler.schedule lambda {
          begin
            if context
              result = proc_bind(func, context).call(*args)
            else
              result = func.call(*args)
            end
          rescue => e
            subject.on_error e
            return
          end
          subject.on_next result
          subject.on_completed
        }
        return subject.as_observable
      }
    end

    private

    # derived from Proc#to_method from Ruby Facets
    # https://github.com/rubyworks/facets/blob/master/lib/core/facets/proc/to_method.rb
    def proc_bind(block, object)
      time = Time.now
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      (class << object; self; end).class_eval do
        define_method(method_name, &block)
        method = instance_method(method_name)
        remove_method(method_name)
        method
      end.bind(object)
    end
  end
end
