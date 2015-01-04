require 'rx'

source = RX::Observable.timer(0, 1)
    .timestamp
    .map {|x| x[:value].to_s + ':' + x[:timestamp].to_i.to_s }
    .take(5)

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

# => Next: 0:1378690776
# => Next: 1:1378690777
# => Next: 2:1378690778
# => Next: 3:1378690779
# => Next: 4:1378690780
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
