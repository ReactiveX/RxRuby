require 'rx'

source = Rx::Observable.range(1, 3)
    .concat_map_observer(
        lambda {|x, i|
            return Rx::Observable.repeat(x, i)
        },
        lambda {|err|
            return Rx::Observable.return(42)
        },
        lambda {
            return Rx::Observable.empty
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
