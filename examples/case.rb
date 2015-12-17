require 'rx_ruby'

sources = {
    'foo' => RxRuby::Observable.return(42),
    'bar' => RxRuby::Observable.return(56)
}

defaultSource = RxRuby::Observable.empty()

source = RxRuby::Observable.case(
    lambda {
        'foo'
    },
    sources,
    defaultSource)

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

#=> Next: 42
#=> Completed
