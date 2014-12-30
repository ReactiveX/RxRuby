require 'rx'

disposable = RX::Disposable.create {
    puts 'disposed'
}

disposable.dispose
# => disposed

disposable = RX::Disposable.empty

disposable.dispose # Does nothing
