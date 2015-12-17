module RxRuby
  module Observable
    def concat_map(selector, result_selector = nil)
      if Proc === result_selector
        return concat_map(lambda {|x, i|
          selector_result = selector.call(x, i)
          if selector_result.respond_to?(:each)
            selector_result = Observable.from(selector_result)
          end
          selector_result.map_with_index {|y, i2|
            result_selector.call(x, y, i, i2)
          }
        })
      end

      if Proc === selector
        _concat_map(selector)
      else
        _concat_map(lambda {|*_| selector })
      end
    end

    private

    def _concat_map(selector)
      map_with_index {|x, i|
        result = selector.call(x, i)
        if result.respond_to?(:each)
          result = Observable.from(result)
        end
        result
      }.concat_all
    end
  end
end
