require 'rx'

#  Without an index
source = RX::Observable.of(42)
  .contains(42)

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

# => Next: true
# => Completed

#  With an index
source = RX::Observable.of(1,2,3)
  .contains(2, 1)

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

# => Next: true
# => Completed
