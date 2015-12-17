require 'rx_ruby'

source = RxRuby::Observable
    .return(42)
    .concat(RxRuby::Observable.return(56), RxRuby::Observable.return(72))

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
