require 'rx'

source = RX::Observable.just(42)

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
