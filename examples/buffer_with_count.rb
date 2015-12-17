require 'rx_ruby'

#  Without a skip
source = RxRuby::Observable.range(1, 6)
    .buffer_with_count(2)

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

# => Next: [1, 2]
# => Next: [3, 4]
# => Next: [5, 6]
# => Completed

#  Using a skip
source = RxRuby::Observable.range(1, 6)
    .buffer_with_count(2, 1)

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

# => Next: [1, 2]
# => Next: [2, 3]
# => Next: [3, 4]
# => Next: [4, 5]
# => Next: [5, 6]
# => Next: [6]
# => Completed
