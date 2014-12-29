require 'rx'

# Choice of either plan, the first set of timers or second set
source = RX::Observable.when(
    RX::Observable.timer(0.2).and(RX::Observable.timer(0.3)).then_do(lambda {|x, y| return 'first' }),
    RX::Observable.timer(0.4).and(RX::Observable.timer(0.5)).then_do(lambda {|x, y| return 'second' }),
)

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

# => Next: first
# => Next: second
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
