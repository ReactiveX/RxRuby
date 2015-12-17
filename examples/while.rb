require 'rx_ruby'

i = 0

# Repeat until condition no longer holds
source = RxRuby::Observable.while(
    lambda { i += 1; i <= 3 },
    RxRuby::Observable.return(42)
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
