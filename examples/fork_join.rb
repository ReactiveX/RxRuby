require 'rx'

#  Using observables and Promises
source = RX::Observable.fork_join(
    RX::Observable.return(42),
    RX::Observable.range(0, 10),
    RX::Observable.from_array([1,2,3]),
    RX::Observable.return(56)
)

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

# => Next: [42, 9, 3, 56]
# => Completed
