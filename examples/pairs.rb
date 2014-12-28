require 'rx'

# Using Standard JavaScript
obj = {
  foo: 42,
  bar: 56,
  baz: 78
}

source = RX::Observable.pairs(obj)

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

# => Next: [:foo, 42]
# => Next: [:bar, 56]
# => Next: [:baz, 78]
# => Completed
