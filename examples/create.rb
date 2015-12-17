require 'rx_ruby'

#  Using a function
source = RxRuby::Observable.create {|observer|
    observer.on_next(42)
    observer.on_completed

    # Note that this is optional, you do not have to return this if you require no cleanup
    lambda {
        puts 'disposed'
    }
}

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

subscription.dispose

# => disposed

#  Using a disposable
source = RxRuby::Observable.create {|observer|
    observer.on_next(42)
    observer.on_completed

    # Note that this is optional, you do not have to return this if you require no cleanup
    RxRuby::Disposable.create {
        puts 'disposed'
    }
}

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
