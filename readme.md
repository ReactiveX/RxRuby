[![Build Status](https://travis-ci.org/ReactiveX/RxRuby.svg?branch=master)](https://travis-ci.org/ReactiveX/RxRuby)
[![GitHub version](https://img.shields.io/github/tag/ReactiveX/RxRuby.svg)](https://github.com/ReactiveX/RxRuby)
[![Downloads](https://img.shields.io/gem/dt/rx.svg)](https://www.npmjs.com/package/rx)
[![Code Climate](https://codeclimate.com/github/ReactiveX/RxRuby/badges/gpa.svg)](https://codeclimate.com/github/ReactiveX/RxRuby)

**[The Need to go Reactive](#the-need-to-go-reactive)** |
**[About the Reactive Extensions](#about-the-reactive-extensions)** |
**[Why RxRuby?](#why-rxruby)** |
**[Contributing](#contributing)** |
**[License](#license)**

# The Reactive Extensions for Ruby (RxRuby) <sup>0.1</sup>... #
*...is a set of libraries to compose asynchronous and event-based programs using observable collections and Enumerable module style composition in Ruby*

## The Need to go Reactive ##

Reactive Programming is a hot topic as of late, especially with such things as the [Reactive Manifesto](http://www.reactivemanifesto.org/).  Applications' needs have changed over time, from simple polling for data to a full reactive system where data is pushed at you.  Each time, we're adding more complexity, data, and asynchronous behavior to our applications.  How do we manage it all?  How do we scale it?  By moving towards "Reactive Architectures" which are event-driven, resilient, and responsive.  With the Reactive Extensions, you have all the tools you need to help build these systems.

## About the Reactive Extensions ##

The Reactive Extensions for Ruby (RxRuby) is a set of libraries for composing asynchronous and event-based programs using observable sequences and fluent query operators that many of you already know in Ruby. Using RxRuby, developers represent asynchronous data streams with Observables, query asynchronous data streams using our many operators, and parameterize the concurrency in the asynchronous data streams using Schedulers. Simply put, RxRuby = Observables + Operators + Schedulers.

When you're authoring applications with Ruby, there may be times when you want to deal with asynchronous and event-based programming, and synchronization is difficult and error prone.

Using RxRuby, you can represent multiple asynchronous data streams (that come from diverse sources, e.g., stock quotes, tweets, computer events, web service requests, etc.), and subscribe to the event stream using the Observer module. The Observable notifies the subscribed Observer instance whenever an event occurs.

Because observable sequences are data streams, you can query them using standard query operators implemented by the Observable module. Thus you can filter, project, reduce, compose, and perform time-based operations on multiple events easily by using these operators. In addition, there are a number of other reactive stream-specific operators that allow powerful queries to be written. Cancellation, exceptions, and synchronization are also handled gracefully by using the methods on the Observable module.

But the best news of all is that you already know how to program like this.  Take for example the following Ruby code, where we get some stock data, manipulate it, and then iterate over the results.

```ruby
# Get evens and square each
someSource
  .select { |x| x.even? }
  .map { |x| x * x }
  .each { |x| puts x.to_s }
```

Using RxRuby, you can accomplish the same kind of thing with a push-based collection by changing `each` to `subscribe`.

```ruby
someSource
  .select { |x| x.even? }
  .map { |x| x * x }
  .subscribe { |x| puts x.to_s }
```

## Why RxRuby? ##

The overall goal of [RxRuby](https://github.com/ReactiveX/RxRuby) is to have a push-based version of the [Enumerable module](http://ruby-doc.org/core-2.1.0/Enumerable.html) with an added notion of time.  Right now, the [Observable module](http://ruby-doc.org/stdlib-1.9.3/libdoc/observer/rdoc/Observable.html) is not quite what we want because it does not allow for composition.  That is no more than a simple implementation of the Subject/Observer pattern from the Gang of Four book, such as the following.

```ruby
require 'observer'

class ArrayObservable
  include Observable

  def initialize(array)
    @array = array
  end

  def run
    index = 0

    while index < @array.length
      change #notify of change
      notify_observers @array[index] # send the current value
      index += 1
      sleep 1
    end
  end
end

class ArrayObserver
  def initialize(observable)
    observable.add_observer(self)
  end

  def update(item)
    puts item.to_s
  end
end

observable = ArrayObservable [1,2]
observer = ArrayObserver.new(observable)
# 1
# 2
```

But how do you enable better composition so that you can compose together Observable instances?  In this current model, this can't happen.  That's why we need the Reactive Extensions for Ruby.  Not only that, we can, at any point in the computation, change the concurrency model to be immediate, on a new thread, or on another machine.

There are many implementations of the Reactive Extensions such as [RxJS](https://github.com/Reactive-Extensions/RxJS), [Rx.NET](https://github.com/reactive-extensions/rx.net), [Java/JVM/Clojure/Scala/JRuby/Groovy](https://github.com/ReactiveX/RxJava) and [ObjC/ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa).  Our goal is to have one operate like the JRuby one, but be available to all users of Ruby, regardless of VM.

We'd like it to be like our JavaScript version, [RxJS](https://github.com/Reactive-Extensions/RxJS) but be able to handle multi-threading, parallelism, and in addition, go across the network.

Instead, our goal is to make the Observable module look exactly like the Enumerable module, in that you can write any query method over it to produce a value, but have it push-based.  This could become yet another competitor to [EventMachine](http://rubyeventmachine.com/), in which we have rich composition over events, whether locally or across the network.

So, take an example, zipping two Arrays.

```ruby
a = [4, 5, 6]
b = [7, 8, 9]

[1, 2, 3].zip(a, b)      #=> [[1, 4, 7], [2, 5, 8], [3, 6, 9]]
[1, 2].zip(a, b)         #=> [[1, 4, 7], [2, 5, 8]]
a.zip([1, 2], [8])       #=> [[4, 1, 8], [5, 2, nil], [6, nil, nil]]
```

Now, we could do something similar in [RxRuby](https://github.com/ReactiveX/RxRuby) with two observable sequences:

```ruby
require 'rx'

a = Rx::Observable.from_array [4, 5, 6]
b = Rx::Observable.from_array [7, 8, 9]

sub = a.zip(b).subscribe { |arr| puts arr.to_s }
# => "[4, 7]"
# => "[5, 8]"
# => "[6, 9]"

# unsubscribes from the sequence and cleans up anything
sub.unsubscribe
```

The difference here is that `zip` returns an `Rx::Observable` instead of an `Enumerable`.  And once you call `subscribe` it's much like `each` but takes an observer, or perhaps just some blocks, lambdas, etc.  The subscription handed back contains the cancellation logic.  For example, if you are listening to events and you no longer want to listen, you can call `unsubscribe` on the `sub` variable above.

What's the end goal?  The first part is that we want to support the main `Enumerable` module methods in the `Observable` module and have them react the same way, but push instead of pull-based.  From there, we can explore such things as multi-threading, and calls across the network.

If you want to find out more, please check out the JavaScript version, [RxJS](https://github.com/Reactive-Extensions/RxJS), which has more details on the overall goals.  

Our overall goal is to make this one of the best Rx libraries out there, better than RxJS, RxPy, ReactiveCocoa, RxJava, etc, all while maintaining the "Ruby Way".

## Contributing ##

You can contribute by reviewing and sending feedback on code checkins, suggesting and trying out new features as they are implemented, submit bugs and help us verify fixes as they are checked in, as well as submit code fixes or code contributions of your own. Note that all code submissions will be rigorously reviewed and tested by the Rx Team, and only those that meet an extremely high bar for both quality and design/roadmap appropriateness will be merged into the source.

## License ##

Copyright (c) Microsoft Open Technologies, Inc.  All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing permissions
and limitations under the License.
