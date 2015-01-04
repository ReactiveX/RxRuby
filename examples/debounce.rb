require 'rx'

times = [
    { value: 0, time: 0.1 },
    { value: 1, time: 0.6 },
    { value: 2, time: 0.4 },
    { value: 3, time: 0.7 },
    { value: 4, time: 0.2 }
]

# Delay each item by time and project value
source = RX::Observable.from(times)
  .flat_map {|item|
    RX::Observable.of(item[:value])
      .delay(item[:time])
  }
  .debounce 0.5 # ms

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

# => Next: 3
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
