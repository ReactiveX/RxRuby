require 'rx'

#  Using an AsyncSubject as a resource which supports the .dispose method
class DisposableResource
  def initialize(value, disposed = false)
    @value = value
    @disposed = disposed
  end

  def value
    if @disposed
      throw Exception.new('Object is disposed')
    end
    @value
  end

  def unsubscribe
    unless @disposed
      @disposed = true
      @value = nil
    end
    puts 'Disposed'
  end
end

source = RX::Observable.using(
  lambda { return DisposableResource.new(42) },
  lambda {|resource|
    subject = RX::AsyncSubject.new
    subject.on_next(resource.value)
    subject.on_completed
    return subject
  }
)

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

# => Next: 42
# => Completed

subscription.dispose

# => Disposed
