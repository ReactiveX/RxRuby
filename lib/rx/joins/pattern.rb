module RX
  class Pattern
    attr_reader :patterns
    def initialize(patterns)
      @patterns = patterns
    end
    def and(other)
      Pattern.new(@patterns.concat(other))
    end
    def then_do(selector = Proc.new)
      Plan.new(self, selector)
    end
  end
end
