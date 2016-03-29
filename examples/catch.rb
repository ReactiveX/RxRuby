require 'rx'

obs1 = Rx::Observable.raise_error(Exception.new('error'))
obs2 = Rx::Observable.return(42)

source = Rx::Observable.rescue_error(obs1, obs2)

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
