require 'rx'

source = RX::Observable.timer(0, 1)
    .time_interval
    .map {|x| x.value.to_s + ":" + x.interval.to_s }
    .take(5)

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

# => Next: 0:0.0000000
# => Next: 1:1.0000000
# => Next: 2:1.0000000
# => Next: 3:1.0000000
# => Next: 4:1.0000000
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
