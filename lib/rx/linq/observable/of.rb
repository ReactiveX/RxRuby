module RX
  class << Observable
    def of(*args)
      scheduler = CurrentThreadScheduler.instance
      if args.size > 0 && Scheduler === args[0]
        scheduler = args.shift
      end
      of_array(args, scheduler)
    end
  end
end
