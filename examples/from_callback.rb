require 'rx'

# Wrap fs.exists
exists = RX::Observable.from_callback(File.method(:exist?))

# Check if file.txt exists
source = exists.call('file.txt')

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
