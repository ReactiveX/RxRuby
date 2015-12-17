require 'rx_ruby'

#  Using observables and Promises
source = RxRuby::Observable.fork_join(
    RxRuby::Observable.return(42),
    RxRuby::Observable.range(0, 10),
    RxRuby::Observable.from_array([1,2,3]),
    RxRuby::Observable.return(56)
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
