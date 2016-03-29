module Rx
  module Observable
    def concat_all
      merge_concurrent(1)
    end
  end
end
