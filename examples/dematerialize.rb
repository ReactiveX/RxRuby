require 'rx'

source = RX::Observable
    .from_array([
        RX::Notification.create_on_next(42),
        RX::Notification.create_on_error(Exception.new('woops'))
    ])
    .dematerialize

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
# => Error: woops
