require 'rx'

source1 = RX::Observable.interval(0.1)
    .time_interval()
    .pluck('interval')
    .take(3)
source2 = RX::Observable.interval(0.15)
    .time_interval()
    .pluck('interval')
    .take(2)

source = RX::Observable.merge(
    source1,
    source2)

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

# => Next: 100
# => Next: 150
# => Next: 100
# => Next: 150
# => Next: 100
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
