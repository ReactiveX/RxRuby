require 'rx'

xs = RX::Observable.interval(0.1)
    .map {|x| 'first' + x.to_s }

ys = RX::Observable.interval(0.1)
    .map {|x| 'second' + x.to_s }

source = xs.group_join(
    ys,
    lambda {|_| return RX::Observable.timer(0) },
    lambda {|_| return RX::Observable.timer(0) },
    lambda {|x, yy|
        return yy.map {|y|
            x + y
        }
    }).merge_all.take(5)

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

# => Next: first0second0
# => Next: first1second1
# => Next: first2second2
# => Next: first3second3
# => Next: first4second4
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
