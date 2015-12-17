require 'rx_ruby'

source = RxRuby::Observable.range(1, 3)
    .reduce(1) {|acc, x| acc * x }

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

# => Next: 6
# => Completed
