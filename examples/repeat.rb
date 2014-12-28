require 'rx'

source = RX::Observable.repeat(42, 3)

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

#=> Next: 42
# => Next: 42
# => Next: 42
# => Completed
