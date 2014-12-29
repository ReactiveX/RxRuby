module RX
  module Observable
    def and(right)
      Pattern.new([self, right]);
    end
  end
end
