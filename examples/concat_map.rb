require 'rx'

source = RX::Observable.range(0, 5)
    .concat_map(lambda {|x, i|
        return RX::Observable
            .interval(0.1)
            .take(x).map { i }
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

# => Next: 1
# => Next: 2
# => Next: 2
# => Next: 3
# => Next: 3
# => Next: 3
# => Next: 4
# => Next: 4
# => Next: 4
# => Next: 4
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end

#  Using an array
source = RX::Observable.of(1,2,3)
  .concat_map(
    lambda {|x, i| return [x,i] },
    lambda {|x, y, ix, iy| return x + y + ix + iy }
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

# => Next: 2
# => Next: 2
# => Next: 5
# => Next: 5
# => Next: 8
# => Next: 8
# => Completed
