require 'rx'

# Using a seed for the accumulate
source = RX::Observable.range(1, 10).aggregate(1) {|acc, x|
    acc * x
}

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

# => Next: 3628800
# => Completed

# Without a seed
source = RX::Observable.range(1, 10).aggregate {|acc, x|
    acc + x
}

subscription = source.subscribe(
    lambda {|x|
        puts 'Next: ' + x.to_s
    },
    lambda {|err|
        puts 'Error: ' + err
    },
    lambda {
        puts 'Completed'
    })

# => Next: 55
# => Completed
