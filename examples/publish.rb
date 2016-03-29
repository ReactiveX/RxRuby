require 'rx'

#  Without publish
interval = Rx::Observable.interval(1)

source = interval
    .take(2)
    .do {|x| puts 'Side effect' }

def create_observer(tag)
    Rx::Observer.create(
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

source.subscribe(create_observer('SourceA'))
source.subscribe(create_observer('SourceB'))

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end

# => Side effect
# => Next: SourceA0
# => Side effect
# => Next: SourceB0
# => Side effect
# => Next: SourceA1
# => Completed
# => Side effect
# => Next: SourceB1
# => Completed

#  With publish
interval = Rx::Observable.interval(1)

source = interval
    .take(2)
    .do {|x| puts 'Side effect' }

def create_observer(tag)
    Rx::Observer.create(
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

connection = published.connect

# => Side effect
# => Next: SourceA0
# => Next: SourceB0
# => Side effect
# => Next: SourceA1
# => Next: SourceB1
# => Completed

while Thread.list.size > 1
  (Thread.list - [Thread.current]).each &:join
end

