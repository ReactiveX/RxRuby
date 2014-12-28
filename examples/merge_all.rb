require 'rx'

source = RX::Observable.range(0, 3)
  .map {|x| RX::Observable.range(x, 3) }
  .merge_all

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

# => Next: 0
# => Next: 1
# => Next: 1
# => Next: 2
# => Next: 2
# => Next: 2
# => Next: 3
# => Next: 3
# => Next: 4
# => Completed
