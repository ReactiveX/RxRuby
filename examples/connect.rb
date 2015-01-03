require 'rx'

interval = RX::Observable.interval(1)

source = interval
    .take(2)
    .do {|x| puts 'Side effect' }

def create_observer(tag)
    return RX::Observer.create(
        lambda {|x|
            puts 'Next: ' + tag + x.to_s
        },
        lambda {|err|
            puts 'Error: ' + err.to_s
        },
        lambda {
            puts 'Completed'
        })
end

published = source.publish

published.subscribe(create_observer('SourceA'))
published.subscribe(create_observer('SourceB'))

# Connect the source
connection = published.connect

# => Side effect
# => Next: SourceA0
# => Next: SourceB0
# => Side effect
# => Next: SourceA1
# => Next: SourceB1
# => Completed
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end
