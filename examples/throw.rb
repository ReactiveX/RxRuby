require 'rx_ruby'

source = RxRuby::Observable.return(42)
    .flat_map { RxRuby::Observable.raise_error(Exception.new('error!')) }

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
