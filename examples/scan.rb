require 'rx_ruby'

#  Without a seed
source = RxRuby::Observable.range(1, 3)
    .scan {|acc, x| acc + x }

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

# => Next: 1
# => Next: 3
# => Next: 6
# => Completed

#  With a seed
source = RxRuby::Observable.range(1, 3)
    .scan(1) {|acc, x| acc * x }

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

# => Next: 1
# => Next: 2
# => Next: 6
# => Completed
