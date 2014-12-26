module RX
  class <<Observable
    def for(sources, result_selector = nil)
      result_selector ||= lambda {|*args| args}
      enum = Enumerator.new {|y|
        sources.each {|v|
          y << result_selector.call(v)
        }
      }
      Observable.concat(enum)
    end
  end
end
