require 'rx_ruby'

source1 = RxRuby::Observable.raise_error(Exception.new('error 1'))
source2 = RxRuby::Observable.raise_error(Exception.new('error 2'))
source3 = RxRuby::Observable.return(42)

source = RxRuby::Observable.on_error_resume_next(source1, source2, source3)

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
