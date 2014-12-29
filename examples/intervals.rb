require 'rx'

source = RX::Observable
    .interval(0.5) # ms
    .time_interval
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

# => Next: (0)@(0.5120988)
# => Next: (1)@(0.5000763)
# => Next: (2)@(0.515575)
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
