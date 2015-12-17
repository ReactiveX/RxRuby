require 'rx_ruby'

first = RxRuby::Observable.timer(0.3).map { 'first' }
second = RxRuby::Observable.timer(0.5).map { 'second' }

source = first.amb(second)

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

# => Next: first
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
