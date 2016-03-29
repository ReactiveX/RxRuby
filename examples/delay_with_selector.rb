require 'rx'

#  With subscription_delay
source = Rx::Observable
    .range(0, 3)
    .delay_with_selector(
        Rx::Observable.timer(0.3),
        lambda {|x|
            return Rx::Observable.timer(x * 0.4)
        }
    )
    .time_interval
    .map {|x| x.value.to_s + ':' + x.interval.to_s }

subscription = source.subscribe(
    lambda {|x|
        puts 'Next: ' + x.to_s
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda {
        puts 'Completed'
    })

# => Next: 0:0.3
# => Next: 1:0.4
# => Next: 2:0.4
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end

#  Without subscription_delay
source = Rx::Observable
    .range(0, 3)
    .delay_with_selector(
        lambda {|x|
            return Rx::Observable.timer(x * 0.4)
        })
    .time_interval
    .map {|x| x.value.to_s + ':' + x.interval.to_s }

subscription = source.subscribe(
    lambda {|x|
        puts 'Next: ' + x.to_s
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda {
        puts 'Completed'
    })

# => Next: 0:0
# => Next: 1:0.4
# => Next: 2:0.4
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
