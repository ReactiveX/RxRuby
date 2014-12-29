require 'rx'

source = RX::Observable.timer(0.2, 0.1)
    .time_interval
    .pluck('interval')
    .take(3)

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

# => Next: 0.2
# => Next: 0.1
# => Next: 0.1
# => Completed

while Thread.list.size > 1
    (Thread.list - [Thread.current]).each &:join
end
