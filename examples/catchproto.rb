require 'rx_ruby'

#  Using a second observable
source = RxRuby::Observable.raise_error(Exception.new)
    .rescue_error(RxRuby::Observable.return(42))

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
# => Completed

#  Using a handler function
source = RxRuby::Observable.raise_error(Exception.new)
    .rescue_error {|e|
        RxRuby::Observable.return(e.is_a? Exception)
    }

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

# => Next: true
# => Completed
