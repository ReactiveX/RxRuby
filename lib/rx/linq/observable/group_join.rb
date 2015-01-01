module RX
  module Observable
    def group_join(right, left_duration_selector, right_duration_selector, result_selector)
      AnonymousObservable.new do |observer|
        group = CompositeSubscription.new
        r = RefCountSubscription.new(group)
        left_map = {}
        right_map = {}
        left_id = 0
        right_id = 0

        left_obs = Observer.configure do |o|
          o.on_next {|value|
            s = Subject.new
            id = left_id
            left_id += 1
            left_map[id] = s

            begin
              result = result_selector.call(value, add_ref(s, r))
            rescue => e
              left_map.values.each {|v| v.on_error(e) }
              observer.on_error(e)
              next
            end
            observer.on_next(result)

            right_map.values.each {|v| s.on_next(v) }

            md = SingleAssignmentSubscription.new
            group.push md

            expire = lambda {
              if left_map.delete(id)
                s.on_completed
              end
              group.delete(md)
            }

            begin
              duration = left_duration_selector.call(value)
            rescue => e
              left_map.values.each {|v| v.on_error(e) }
              observer.on_error(e)
              next
            end

            md.subscription = duration.take(1).subscribe(
              lambda {|_| },
              lambda {|e|
                left_map.values.each {|v| v.on_error(e) }
                observer.on_error(e)
              },
              expire)
          }

          o.on_error {|e|
            left_map.values.each {|v| v.on_error(e) }
            observer.on_error(e)
          }

          o.on_completed &observer.method(:on_completed)
        end
        group.push self.subscribe(left_obs)

        right_obs = Observer.configure do |o|
          o.on_next {|value|
            id = right_id
            right_id += 1
            right_map[id] = value

            md = SingleAssignmentSubscription.new
            group.push md

            expire = lambda {
              right_map.delete(id)
              group.delete(md)
            }

            begin
              duration = right_duration_selector.call(value)
            rescue => e
              right_map.values.each {|v| v.on_error(e) }
              observer.on_error(e)
              next
            end

            md.subscription = duration.take(1).subscribe(
              lambda {|_| },
              lambda {|e|
                left_map.values.each {|v| v.on_error(e) }
                observer.on_error(e)
              },
              expire)
          }

          o.on_error {|e|
            left_map.values.each {|v| v.on_error(e) }
            observer.on_error(e)
          }
        end
        group.push right.subscribe(right_obs)

        r
      end
    end

    private
    def add_ref(xs, r)
      AnonymousObservable.new do |observer|
        CompositeSubscription.new [r.subscription, xs.subscribe(observer)]
      end
    end
  end
end
