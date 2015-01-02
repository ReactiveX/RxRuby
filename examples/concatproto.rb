require 'rx'

source = RX::Observable
    .return(42)
    .concat(RX::Observable.return(56), RX::Observable.return(72))

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

# => Next: 42
# => Next: 56
# => Next: 72
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
