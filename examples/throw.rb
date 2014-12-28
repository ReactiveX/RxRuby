require 'rx'

source = RX::Observable.return(42)
    .flat_map { RX::Observable.raise_error(Exception.new('error!')) }

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

# => Error: error!
