require 'rx'

#  Using Observable sequences
source1 = Rx::Observable.return(42)
source2 = Rx::Observable.return(56)

source = Rx::Observable.concat(source1, source2)

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
