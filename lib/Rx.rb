# Copyright (c) Microsoft Corporation. All rights reserved. See License.txt in the project root

require 'thread.rb'

# Disposables

class Disposable
	
	def initialize(&disposable_action)
		@disposable_action = disposable_action
		@gate = Mutex.new
		@disposed = false
	end
	
	def dispose
		should_dispose = false
		@gate.synchronize do
			should_dispose = !@disposed
		end
		if should_dispose
			@disposable_action.call
		end
	end
end

class AutoDetachDisposable
	def initialize(observer)
		@gate = Mutex.new
		@observer = observer
		@disposed = false
		@disposable = nil
	end
	
	def dispose
		disposable = nil
		@observer.stop
		@gate.synchronize do
			unless @disposed
				@disposed = true
				disposable = @disposable
			end
		end
		
		unless disposable.nil?
			disposable.dispose
		end
	end
	
	def set(disposable)
		flag = false
		@gate.synchronize do
			unless @disposed
				@disposable = disposable
			else
				flag = true
			end
		end
		if flag
			disposable.dispose
		end		
	end
end

class MutableDisposable

	def initialize
		@current = nil
		@disposed = false
		@gate = Mutex.new
	end
	
	def replace(disposable)
		shouldDispose = false
		@gate.synchronize do
			shouldDispose = @disposed		
			unless shouldDispose
				unless @current.nil?
					@current.dispose
				end
				@current = disposable
			end
		end
		if shouldDispose && !disposable.nil?
			disposable.dispose
		end
	end

	def dispose
		@gate.synchronize do
			unless @disposed
				@disposed = true
				unless @current.nil?
					@current.dispose
					@current = nil
				end
			end
		end
	end
end

class EmptyDisposable 
	def dispose
	
	end
end

class BooleanDisposable

	def initialize
		@is_disposed = false
	end
	
	def disposed?
		@is_disposed
	end
	
	def dispose
		@is_disposed = true
	end
end

class CompositeDisposable
	
	def initialize(disposables = [])
		@disposables = disposables
		@disposed = false
		@gate = Mutex.new
	end
	
	def dispose
		currentDisposables = nil
		@gate.synchronize do
			unless @disposed
				@disposed = true
				currentDisposables = @disposables
				@disposables = []
			end
		end
		unless currentDisposables.nil?
			currentDisposables.each {|disposable| disposable.dispose}
		end
	end
	
	def add(disposable)
		shouldDispose = false
		@gate.synchronize do
			shouldDispose = @disposed
			unless @disposed
				@disposables.push(disposable)
			end
		end
		if shouldDispose
			disposable.dispose
		end
	end
	
	def clear
		currentDisposables = nil
		@gate.synchronize do
			currentDisposables = @disposables
			@disposables = []
		end
		currentDisposables.each {|disposable| disposable.dispose}
	end
	
	def count 
		@disposables.length
	end
	
	def remove(disposable)
		should_dispose = false
		@gate.synchronize do
			should_dispose = @disposables.delete(disposable).dispose.nil?
		end
		if should_dispose
			disposable.dispose
		end
		should_dispose
	end
end

#Scheduler

class Scheduler

	def initialize(schedule_action, schedule_with_time_action, now_action)
		@schedule_action = schedule_action
		@schedule_with_time_action = schedule_with_time_action
		@now_action = now_action	
	end

	@@immediate_scheduler = Scheduler.new( 
		lambda do |action|
			action.call
			EmptyDisposable.new
		end,
		lambda do |action, due_time|
			sleep(due_time)
			action.call
			EmptyDisposable.new
		end,
		lambda { Time.now } )
	
  @@new_thread_scheduler = Scheduler.new( 
		lambda do |action|
			t = Thread.new(&action)
			Disposable.new do
				t.kill
			end
		end,
		lambda do |action, due_time|
			t = Thread.new do
				sleep(due_time)
				action.call
			end
			Disposable.new do
				t.kill
			end
		end,
		lambda { Time.now })
	
	def schedule(&action)
		@schedule_action.call(action)
	end
	
	def schedule_with_time(dueTime, &action)
		@schedule_with_time_action.call(action, dueTime)
	end
	
	def now
		@now_action.call
	end
	
	def self.immediate		
		@@immediate_scheduler
	end
	
	def self.new_thread
		@@new_thread_scheduler
	end
	def schedule_recursive(&action)
		group = CompositeDisposable.new
		
		recursiveAction = proc do
			action.call(proc do
				isAdded = false
				isDone = false
				d = self.schedule do
					recursiveAction.call
					if isAdded
						group.remove(d)
					else
						isDone = true
					end					
				end
				unless isDone
					group.add(d)
					isAdded = true
				end
			end)
		end
		group.add(self.schedule(&recursiveAction))
		group
	end
end	
	
#Observer

class Observer
	@on_next_action
	@on_error_action
	@on_completed_action

	def initialize
		@on_error_action = lambda {|exception| raise exception }
		@on_completed_action = lambda {}
		yield self if block_given?
	end
	
	def with_on_next(&on_next_action)
		@on_next_action = on_next_action
		self
	end
	
	def with_on_error(&on_error_action)
		@on_error_action = on_error_action
		self
	end
	
	def with_on_completed(&on_completed_action)
		@on_completed_action = on_completed_action
		self
	end
	
	def on_next(value)
		@on_next_action.call(value)
	end
	
	def on_error(exception)
		@on_error_action.call(exception)
	end
	
	def on_completed
		@on_completed_action.call
	end
end

class AbstractObserver
	def initialize
		@stopped = false
	end
	
	def on_completed
		unless @stopped
			@stopped = true
			self.completed
		end
	end
	
	def on_error(exception)
		# TODO: Error checking
		
		unless @stopped
			@stopped = true
			self.error(exception)
		end
	end
	
	def on_next(value)
		unless @stopped
			self.next(value)
		end
	end
	
	def stop
		@stopped = true
	end
end

class AutoDetachObserver < AbstractObserver
	def initialize(observer)
		@group = CompositeDisposable.new
		@observer = observer
	end
	
	def add(disposable)
		@group.add(disposable)
	end
	
	def completed
		@observer.on_completed
		@group.dispose
	end
	
	def error(exception)
		@observer.on_error(exception)
		@group.dispose
	end
	
	def next(value)
		@observer.on_next(value)
	end
end

#Enumerable
module Enumerable
	def subscribe(observer, scheduler = Scheduler.immediate)
		begin
			self.each do |e|
				scheduler.schedule do
					observer.on_next(e)
				end
			end
		rescue Exception => ex
			observer.on_error(ex)
			return
		end
		
		observer.on_completed
	end
	
	def to_observable(scheduler = Scheduler.immediate)
		AnonymousObservable.new do |observer|
			self.subscribe(observer, scheduler)
		end
	end
	
end

#Observable

module Observable

	def initialize(&subscribe)
		@subscribe_action = subscribe
	end

	def subscribe(observer)
		auto_detach_observer = observer.is_a?(AutoDetachObserver) ? observer : AutoDetachObserver.new(observer)
		subscription = AutoDetachDisposable.new(auto_detach_observer)
		auto_detach_observer.add(subscription)

		#TODO: ensure trampoline
		subscription.set(@subscribe_action.call(auto_detach_observer))
		
		subscription
	end
	
	def self.create_with_disposable(&subscribe)
	
	end
	
	def self.never
		AnonymousObservable.new do |observer|
			EmptyObservable.new
		end
	end
	
	def self.empty(scheduler = Scheduler.immediate)
		AnonymousObservable.new do |observer|
			scheduler.schedule do
				observer.on_completed
			end
		end
	end	
	
	def self.return(value, scheduler = Scheduler.immediate)
		
		AnonymousObservable.new do |observer|
			scheduler.schedule do
				observer.on_next(value)
				observer.on_completed
			end
		end
	end
	
	def self.throw(exception, scheduler = Scheduler.immediate)
		AnonymousObservable.new do |observer|
			scheduler.schedule do
				observer.on_error(exception)
			end
		end
	end	
	
	def self.generate(initial_state, condition, result_selector, iterate, scheduler = Scheduler.immediate)
		AnonymousObservable.new do | observer|
			state = initial_state
			first = true
			
			scheduler.schedule_recursive do |this|
				hasResult = false
				result = nil
				begin
					if first
						first = false
					else
						state = iterate.call(state)
					end
					hasResult = condition.call(state)
					if hasResult
						result = result_selector.call(state)
					end
				rescue => err
					observer.on_error(err)
					return
				end
				if hasResult
					observer.on_next(result)
					this.call
				else
					observer.on_completed
				end
			end
		end
	end
	
	
	def self.range(start, length, scheduler = Scheduler.immediate)
		max = start + length - 1
		Observable.generate(start, lambda {|x| x <= max}, lambda {|x| x}, lambda {|x| x + 1 }, scheduler)
	end	
	
	def merge
		AnonymousObservable.new do |observer|
			gate = Mutex.new
			stopped = false
			group = CompositeDisposable.new
			outer_subscription = MutableDisposable.new
			group.add(outer_subscription)	

			outer_subscription.replace(self.subscribe(Observer.new do |o|
				o.with_on_next do |inner_source|
					inner_subscription = MutableDisposable.new
					group.add(inner_subscription)
					inner_subscription.replace(inner_source.subscribe(Observer.new do |inner_o|
						inner_o.with_on_next do |inner_value|
							gate.synchronize do
								observer.on_next(inner_value)
							end
						end
						
						inner_o.with_on_error do |inner_error|
							gate.synchronize do
								observer.on_error(inner_error)
							end
						end
						
						inner_o.with_on_completed do
							group.remove(inner_subscription)
							if stopped && group.count == 1
								gate.synchronize do
									observer.on_completed
								end
							end							
						end
					end))
				end

				o.with_on_error do |exception|
					gate.synchronize do
						observer.on_error(exception)
					end
				end
				
				o.with_on_completed do
					stopped = true
					if group.count == 1
						gate.synchronize do
							observer.on_completed
						end
					end					
				end
			end))
			gate
		end
	end
	
	def where(&predicate)
		AnonymousObservable.new do |observer|
			on_next_action = proc do |next_value| 
				shouldFire = false
				begin
					shouldFire = predicate.call(next_value)
				rescue => err
					observer.on_error(err)
					return
				end
				if shouldFire
					observer.on_next(next_value) 
				end
			end
			
			obs = Observer.new do |o|
				o.with_on_next do |next_value| 
					shouldFire = false
					begin
						shouldFire = predicate.call(next_value)
					rescue => err
						observer.on_error(err)
						return
					end
					if shouldFire
						observer.on_next(next_value) 
					end
				end
				
				o.with_on_error do |exception|
					observer.on_error(exception)
				end
				
				o.with_on_completed do 
					observer.on_completed
				end
			end

			self.subscribe(obs)
		end
	end
	
	def select(&selector)
		AnonymousObservable.new do |observer|
			obs = Observer.new do |o|
				o.with_on_next do |next_value| 
					value = nil
					begin
						value = selector.call(next_value)
					rescue => err
						observer.on_error(err)
						return
					end
					observer.on_next(value) 
				end
				
				o.with_on_error do |exception|
					observer.on_error(exception)
				end
				
				o.with_on_completed do 
					observer.on_completed
				end
			end
			self.subscribe(obs)
		end
	end
	
	def select_many(&selector)
		self.select(&selector).merge
	end

	def finally(&finally_action)
		AnonymousObservable.new do |observer|
			subscription = self.subscribe(observer)
			Disposable.new do
				begin
					subscription.dispose
				ensure
					finally_action.call
				end
			end
		end
	end
end

class AnonymousObservable
	include Observable
end

observer = Observer.new do |o|
	o.with_on_next {|next_value| puts "Next: #{next_value}" }
	o.with_on_error {|exception| puts "Exception: #{exception.message}"}
	o.with_on_completed { puts "done!" }	
end

#observable = Observable.generate(0, { :condition => proc {|i| i < 10}, :iterate => proc {|i| i+1}, :result_selector => proc {|i|i}}).
# observable = Observable.range(2,2, Scheduler.new_thread).select_many do |x|
	# Observable.range(x * 3, 3, Scheduler.new_thread)
# end

observable1 = Observable.empty
observable2 = Observable.return(42)
observable3 = Observable.throw(Exception.new("oops!"))
observable4 = Observable.generate(
	0,
	lambda {|x| x < 10},
	lambda {|x| x},
	lambda {|x| x + 1})
observable5 = Observable.range(0, 10)
observable6 = (1..10).to_observable
observable7 = observable6.
	where {|x| x % 2 == 0}
observable8 = observable7.
	select {|x| x * x + x}
observable9 = Observable.range(0, 2).select_many do |x|
	Observable.range(x * 25, 2)
end
observable10 = Observable.return(42).
	finally { puts 'finally doing something with my life' }

# observable1.subscribe(observer)
# observable2.subscribe(observer)
# observable3.subscribe(observer)
# observable4.subscribe(observer)
# observable5.subscribe(observer)
# observable6.subscribe(observer)
# (1..10).subscribe(observer)
# observable7.subscribe(observer)
# observable8.subscribe(observer)
# observable9.subscribe(observer)
observable10.subscribe(observer)

# bart = "erik"

# Observable.throw(Exception.new("woops!")).subscribe(Class.new(Observer) do
	# @@bart = bart

	# def on_next(el)
		# puts "#{@@bart} #{el}"
	# end
	
	# def on_error(exception)
		# puts "#{exception.message}"
	# end

# end.new)

gets
