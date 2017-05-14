require 'rx'

# With an interval time
source = Rx::Observable.interval(0.05)
    .delay(0.01)
    .sample(0.15)
    .take(2)

source.subscribe(
    lambda { |x|
        puts 'Next: ' + x.to_s
    },
    lambda { |err|
        puts 'Error: ' + err.inspect
    },
    lambda {
        puts 'Completed'
    })

# => Next: 1
# => Next: 4
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each(&:join)
end

# With a sampler
source = Rx::Observable.interval(0.05)
    .sample(Rx::Observable.interval(0.15).delay(0.01))
    .take(2)

source.subscribe(
    lambda { |x|
        puts 'Next: ' + x.to_s
    },
    lambda { |err|
        puts 'Error: ' + err.inspect
    },
    lambda {
        puts 'Completed'
    })

# => Next: 2
# => Next: 5
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each(&:join)
end
