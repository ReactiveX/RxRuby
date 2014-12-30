require 'rx'

# This will never produce a value, hence never calling any of the callbacks
source = RX::Observable.never

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
