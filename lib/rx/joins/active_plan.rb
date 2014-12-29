module RX
  class ActivePlan
    def initialize(join_observer_array, on_next, on_completed)
      @join_observer_array = join_observer_array
      @on_next = on_next
      @on_completed = on_completed
      @join_observers = {}
      @join_observer_array.each {|x|
        @join_observers[x] = x
      }
    end

    def dequeue
      @join_observers.each {|_, v| v.queue.shift }
    end

    def match
      has_values = true
      @join_observer_array.each {|v|
        if v.queue.length == 0
          has_values = false
          break
        end
      }
      if has_values
        first_values = []
        is_completed = false
        @join_observer_array.each {|v|
          first_values.push v.queue[0]
          is_completed = true if v.queue[0].on_completed?
        }
        if is_completed
          @on_completed.call
        else
          dequeue
          values = []
          first_values.each {|v|
            values.push v.value
          }
          @on_next.call(*values)
        end
      end
    end
  end
end
