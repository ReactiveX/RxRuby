require 'rx_ruby'

#  Without a predicate
source = RxRuby::Observable.range(0, 10).count

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

# => Next: 10
# => Completed

#  With a predicate
source = RxRuby::Observable.range(0, 10)
    .count {|x| x % 2 === 0 }

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

# => Next: 5
# => Completed
