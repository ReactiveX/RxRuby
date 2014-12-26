require 'rx'

source = RX::Observable.generate(
    0,
    lambda {|x| x < 3 }, # condition
    lambda {|x| x + 1 }, # iterate
    lambda {|x| x }  # resultSelector
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

# => Next: 0
# => Next: 1
# => Next: 2
# => Completed
