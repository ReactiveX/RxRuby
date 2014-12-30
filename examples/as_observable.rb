require 'rx'

# Create subject
subject = RX::AsyncSubject.new

# Send a value
subject.on_next(42)
subject.on_completed

# Hide its type
source = subject.as_observable

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
# => Completed
