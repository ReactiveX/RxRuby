require 'rx_ruby'

obs1 = RxRuby::Observable.raise_error(Exception.new('error'))
obs2 = RxRuby::Observable.return(42)

source = RxRuby::Observable.rescue_error(obs1, obs2)

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
