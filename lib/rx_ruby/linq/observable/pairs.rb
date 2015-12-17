module RxRuby
  class << Observable
    def pairs(obj, scheduler = CurrentThreadScheduler.instance)
      of_enumerable(obj, scheduler)
    end
  end
end
