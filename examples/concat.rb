require 'rx'

#  Using Observable sequences
source1 = RX::Observable.return(42)
source2 = RX::Observable.return(56)

source = RX::Observable.concat(source1, source2)

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

# => Next: 42
# => Next: 56
# => Completed
