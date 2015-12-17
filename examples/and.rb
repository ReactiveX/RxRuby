require 'rx_ruby'

# Choice of either plan, the first set of timers or second set
source = RxRuby::Observable.when(
    RxRuby::Observable.timer(0.2).and(RxRuby::Observable.timer(0.3)).then_do(lambda {|x, y| return 'first' }),
    RxRuby::Observable.timer(0.4).and(RxRuby::Observable.timer(0.5)).then_do(lambda {|x, y| return 'second' }),
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
