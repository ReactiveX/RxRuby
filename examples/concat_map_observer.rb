require 'rx'

source = RX::Observable.range(1, 3)
    .concat_map_observer(
        lambda {|x, i|
            return RX::Observable.repeat(x, i)
        },
        lambda {|err|
            return RX::Observable.return(42)
        },
        lambda {
            return RX::Observable.empty
        })

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

# => Next: 2
# => Next: 3
# => Next: 3
# => Completed
