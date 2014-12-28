require 'rx'

source = RX::Observable.range(0, 3)

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

# => Next: 0
# => Next: 1
# => Next: 2
# => Completed
