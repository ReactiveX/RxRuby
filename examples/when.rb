require 'rx'

# Fire each plan when both are ready
source = Rx::Observable.when(
  Rx::Observable.timer(0.1).and(Rx::Observable.timer(0.5)).then_do(lambda {|x, y| return 'first' }),
  Rx::Observable.timer(0.4).and(Rx::Observable.timer(0.3)).then_do {|x, y| 'second' }
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

# => Next: second
# => Next: first
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
