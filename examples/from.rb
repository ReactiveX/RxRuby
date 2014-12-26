require 'rx'

# Array-like object (arguments) to Observable
def f(*arguments)
  RX::Observable.from(arguments)
end

f(1, 2, 3).subscribe(
  lambda {|x|
    puts 'Next: ' + x.to_s
  },
  lambda {|err|
    puts 'Error: ' + err.to_s
  },
  lambda {
    puts 'Completed'
  })

# => Next: 1
# => Next: 2
# => Next: 3
# => Completed

# Any iterable object...
s = ["foo", :window]
RX::Observable.from(s).subscribe(
  lambda {|x|
    puts 'Next: ' + x.to_s
  },
  lambda {|err|
    puts 'Error: ' + err.to_s
  },
  lambda {
    puts 'Completed'
  })
# => Next: foo
# => Next: window
# => Completed

# Map
m = {1 => 2, 2 => 4, 4 => 8}
RX::Observable.from(m).subscribe(
  lambda {|x|
    puts 'Next: ' + x.to_s
  },
  lambda {|err|
    puts 'Error: ' + err.to_s
  },
  lambda {
    puts 'Completed'
  })
# => Next: [1, 2]
# => Next: [2, 4]
# => Next: [4, 8]
# => Completed

# String
RX::Observable.from("foo".to_enum(:each_char)).subscribe(
  lambda {|x|
    puts 'Next: ' + x.to_s
  },
  lambda {|err|
    puts 'Error: ' + err.to_s
  },
  lambda {
    puts 'Completed'
  })
# => Next: f
# => Next: o
# => Next: o
# => Completed

# Using an arrow function as the map function to
# manipulate the elements
RX::Observable.from([1, 2, 3], lambda {|x, i| x + x }).subscribe(
  lambda {|x|
    puts 'Next: ' + x.to_s
  },
  lambda {|err|
    puts 'Error: ' + err.to_s
  },
  lambda {
    puts 'Completed'
  })
# => Next: 2
# => Next: 4
# => Next: 6
# => Completed

# Generate a sequence of numbers
RX::Observable.from(5.times, lambda {|v, k| k }).subscribe(
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
# => Next: 2
# => Next: 3
# => Next: 4
# => Completed
