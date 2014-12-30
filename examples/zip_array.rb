require 'rx'

range = RX::Observable.range(0, 5)

source = RX::Observable.zip(
    range,
    range.skip(1),
    range.skip(2)
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

# => Next: [0, 1, 2]
# => Next: [1, 2, 3]
# => Next: [2, 3, 4]
# => Completed
