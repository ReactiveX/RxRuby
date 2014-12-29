module RX
  class <<Observable
    def when(*plans)
      AnonymousObservable.new do |observer|
        active_plans = []
        external_subscriptions = {}
        out_observer = Observer.configure {|o|
          o.on_next &observer.method(:on_next)
          o.on_error {|err|
            external_subscriptions.each {|_, v|
              v.on_error err
            }
          }
          o.on_completed &observer.method(:on_completed)
        }
        begin
          plans.each {|x|
            active_plans.push x.activate(external_subscriptions, out_observer, lambda {|active_plan|
              active_plans.delete(active_plan)
              active_plans.length == 0 && observer.on_completed 
            })
          }
        rescue => e
          Observable.raise_error(e).subscribe(observer)
        end
        group = CompositeSubscription.new
        external_subscriptions.each {|_, join_observer|
          join_observer.subscribe
          group.push join_observer
        }

        group
      end
    end
  end
end
