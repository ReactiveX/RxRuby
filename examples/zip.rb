require 'rx'

# Using arguments
range = Rx::Observable.range(0, 5)

source = Rx::Observable.zip(
    range,
    range.skip(1),
    range.skip(2)) {|s1, s2, s3|
        s1.to_s + ':' + s2.to_s + ':' + s3.to_s
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

# => Next: 0:1:2
# => Next: 1:2:3
# => Next: 2:3:4
# => Completed
