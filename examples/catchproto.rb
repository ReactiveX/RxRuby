require 'rx'

#  Using a second observable
source = Rx::Observable.raise_error(Exception.new)
    .rescue_error(Rx::Observable.return(42))

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
source = Rx::Observable.raise_error(Exception.new)
    .rescue_error {|e|
        Rx::Observable.return(e.is_a? Exception)
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
