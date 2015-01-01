require 'rx'

source = RX::Observable.timer(0, 0.1)
    .take(5)
    .to_a

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

# => Next: [0, 1, 2, 3, 4]
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
