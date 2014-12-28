require 'rx'

func = RX::Observable.to_async(lambda {|x, y|
    return x + y
})

# Execute function with 3 and 4
source = func.call(3, 4)

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

# => Next: 7
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
