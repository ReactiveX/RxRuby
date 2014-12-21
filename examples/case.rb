require 'rx'

sources = {
    'foo' => RX::Observable.return(42),
    'bar' => RX::Observable.return(56)
}

defaultSource = RX::Observable.empty()

source = RX::Observable.case(
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
