require 'rx'

sources = {
    'foo' => Rx::Observable.return(42),
    'bar' => Rx::Observable.return(56)
}

defaultSource = Rx::Observable.empty()

source = Rx::Observable.case(
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
