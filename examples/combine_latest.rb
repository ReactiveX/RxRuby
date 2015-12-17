require 'rx_ruby'

# Have staggering intervals
source1 = RxRuby::Observable.interval(0.1)
    .map {|i| 'First: ' + i.to_s }

source2 = RxRuby::Observable.interval(0.15)
    .map {|i| 'Second: ' + i.to_s }

# Combine latest of source1 and source2 whenever either gives a value
source = RxRuby::Observable.combine_latest(
        source1,
        source2) {|s1, s2| s1.to_s + ', ' + s2.to_s }
    .take(4)

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

# => Next: First: 0, Second: 0
# => Next: First: 1, Second: 0
# => Next: First: 1, Second: 1
# => Next: First: 2, Second: 1
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
