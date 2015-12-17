require 'rx_ruby'

#  Using Observables
array = [1, 2, 3]

source = RxRuby::Observable.for(
    array,
    lambda {|x|
        RxRuby::Observable.return(x)
    })

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
# => Next: 3
# => Completed
