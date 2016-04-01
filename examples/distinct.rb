require 'rx'

#  Without key selector
source = Rx::Observable.from_array([
        42, 24, 42, 24
    ])
    .distinct

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
# => Next: 24
# => Completed

#  With key selector
source = Rx::Observable.from_array([
        {value: 42}, {value: 24}, {value: 42}, {value: 24}
    ])
    .distinct {|x| x[:value] }

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

# => Next: {:value=>42}
# => Next: {:value=>24}
# => Completed
