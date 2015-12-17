require 'rx_ruby'

disposable = RxRuby::Disposable.create {
    puts 'disposed'
}

disposable.dispose
# => disposed

disposable = RxRuby::Disposable.empty

disposable.dispose # Does nothing
