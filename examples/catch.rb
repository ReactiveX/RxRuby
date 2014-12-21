require 'rx'

obs1 = RX::Observable.throw(new Error('error'))
obs2 = RX::Observable.return(42)

source = RX::Observable.catch(obs1, obs2)

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
