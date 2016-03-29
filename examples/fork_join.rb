require 'rx'

#  Using observables and Promises
source = Rx::Observable.fork_join(
    Rx::Observable.return(42),
    Rx::Observable.range(0, 10),
    Rx::Observable.from_array([1,2,3]),
    Rx::Observable.return(56)
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
