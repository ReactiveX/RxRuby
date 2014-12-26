module RX
  class <<Observable
    def fork_join(*all_sources)
      AnonymousObservable.new {|subscriber|
        count = all_sources.length
        if count == 0
          subscriber.on_completed
          Subscription.empty
        end
        group = CompositeSubscription.new
        finished = false
        has_results = Array.new(count)
        has_completed  = Array.new(count)
        results  = Array.new(count)

        count.times {|i|
          source = all_sources[i]
          group.push(
            source.subscribe(
              lambda {|value|
                if !finished
                  has_results[i] = true
                  results[i] = value
                end
              },
              lambda {|e|
                finished = true
                subscriber.on_error e
                group.dispose
              },
              lambda {
                if !finished
                  if !has_results[i]
                      subscriber.on_completed
                      return
                  end
                  has_completed[i] = true
                  count.times {|ix|
                    if !has_completed[ix]
                      return
                    end
                  }
                  finished = true
                  subscriber.on_next results
                  subscriber.on_completed
                end
              }
            )
          )
        }
        group
      }
    end
  end
end
