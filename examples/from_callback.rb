require 'rx_ruby'

# Wrap fs.exists
exists = RxRuby::Observable.from_callback(File.method(:exist?))

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
