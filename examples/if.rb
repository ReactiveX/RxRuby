require 'rx'

# This uses and only then source
should_run = true

source = Rx::Observable.if(
    lambda { return should_run },
    Rx::Observable.return(42)
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

# => Next: 42
# => Completed

# The next example uses an elseSource
should_run = false

source = Rx::Observable.if(
    lambda { return should_run },
    Rx::Observable.return(42),
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

# => Next: 56
# => Completed
