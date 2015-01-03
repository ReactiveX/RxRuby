require 'rx'

#  Using a second observable
source = RX::Observable.raise_error(Exception.new)
    .rescue_error(RX::Observable.return(42))

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
source = RX::Observable.raise_error(Exception.new)
    .rescue_error {|e|
        RX::Observable.return(e.is_a? Exception)
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
