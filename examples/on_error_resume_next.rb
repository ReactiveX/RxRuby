require 'rx'

source1 = RX::Observable.raise_error(Exception.new('error 1'))
source2 = RX::Observable.raise_error(Exception.new('error 2'))
source3 = RX::Observable.return(42)

source = RX::Observable.on_error_resume_next(source1, source2, source3)

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
