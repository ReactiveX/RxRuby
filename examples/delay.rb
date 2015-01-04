require 'rx'

#  Using an absolute time to delay by a second
source = RX::Observable.range(0, 3)
    .delay(Time.now + 1)

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

# => Next: 0
# => Next: 1
# => Next: 2
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end

#  Using an relatove time to delay by a second
source = RX::Observable.range(0, 3)
    .delay(1)

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

# => Next: 0
# => Next: 1
# => Next: 2
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
