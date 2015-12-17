require 'rx_ruby'

#  Without a skip
source = RxRuby::Observable.interval(0.1)
    .window_with_time(0.5)
    .take(3)

subscription = source.subscribe(
    lambda {|child|
        child.to_a.subscribe(
            lambda {|x|
                puts 'Child Next: ' + x.to_s
            },
            lambda {|err|
                puts 'Child Error: ' + err.to_s
            },
            lambda {
                puts 'Child Completed'
            }
        )
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda {
        puts 'Completed'
    })

# => Child Next: [0, 1, 2, 3]
# => Child Completed
# => Completed
# => Child Next: [4, 5, 6, 7, 8]
# => Child Completed
# => Child Next:  [9, 10, 11, 12, 13]
# => Child Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end

#  Using a skip
source = RxRuby::Observable.interval(0.1)
    .window_with_time(0.5, 0.1)
    .take(3)

subscription = source.subscribe(
    lambda {|child|

        child.to_a.subscribe(
            lambda {|x|
                puts 'Child Next: ' + x.to_s
            },
            lambda {|err|
                puts 'Child Error: ' + err.to_s
            },
            lambda {
                puts 'Child Completed'
            }
        )
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda {
        puts 'Completed'
    })

# => Completed
# => Child Next: [0, 1, 2, 3, 4]
# => Child Completed
# => Child Next: [1, 2, 3, 4, 5]
# => Child Completed
# => Child Next: [2, 3, 4, 5, 6]
# => Child Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
