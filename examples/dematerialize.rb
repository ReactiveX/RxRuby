require 'rx_ruby'

source = RxRuby::Observable
    .from_array([
        RxRuby::Notification.create_on_next(42),
        RxRuby::Notification.create_on_error(Exception.new('woops'))
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
