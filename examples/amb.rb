require 'rx_ruby'

# Using Observable sequences
source = RxRuby::Observable.amb(
    RxRuby::Observable.timer(0.5).map { 'foo' },
    RxRuby::Observable.timer(0.2).map { 'bar' }
)

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

# => Next: bar
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
