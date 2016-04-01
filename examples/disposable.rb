require 'rx'

disposable = Rx::Disposable.create {
    puts 'disposed'
}

disposable.dispose
# => disposed

disposable = Rx::Disposable.empty

disposable.dispose # Does nothing
