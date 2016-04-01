require 'rx'

#  Without a skip
source = Rx::Observable.interval(0.1)
    .buffer_with_time(0.5)
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

# => Next: [0, 1, 2, 3]
# => Next: [4, 5, 6, 7, 8]
# => Next: [9, 10, 11, 12, 13]
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end

#  Using a skip
source = Rx::Observable.interval(0.1)
    .buffer_with_time(0.5, 0.1)
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

# => Next: [0, 1, 2, 3, 4]
# => Next: [1, 2, 3, 4, 5]
# => Next: [2, 3, 4, 5, 6]
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
