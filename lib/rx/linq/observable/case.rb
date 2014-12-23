module RX
  class <<Observable
    def case(selector, sources, defaultSourceOrScheduler = Observable.empty)
      defer {
        if Scheduler === defaultSourceOrScheduler
          defaultSourceOrScheduler = Observable.empty(defaultSourceOrScheduler)
        end

        result = sources[selector.call]
        result || defaultSourceOrScheduler
      }
    end
    alias :switchCase :case
  end
end
