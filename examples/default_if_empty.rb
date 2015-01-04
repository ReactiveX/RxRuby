require 'rx'

#  Without a default value
source = RX::Observable.empty.default_if_empty

subscription = source.subscribe(
    lambda {|x|
        puts 'Next: ' + x.inspect
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda {
        puts 'Completed'
    })

# => Next: nil
# => Completed

#  With a default_value
source = RX::Observable.empty.default_if_empty(false)

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

# => Next: false
# => Completed
