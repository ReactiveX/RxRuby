require 'rx'

i = 0

# Repeat until condition no longer holds
source = RX::Observable.while(
    lambda { i += 1; i <= 3 },
    RX::Observable.return(42)
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

# => Next: 42
# => Next: 42
# => Next: 42
# => Completed
