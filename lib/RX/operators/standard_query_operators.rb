# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/current_thread_scheduler'
require 'rx/concurrency/immediate_scheduler'
require 'rx/core/observer'
require 'rx/subscriptions/composite_subscription'
require 'rx/subscriptions/subscription'

module RX

  module Observable

    # Standard Query Operators

    # Returns the elements of the specified sequence or the type parameter's default value in a singleton sequence if the sequence is empty.
    def default_if_empty(default_value)
      AnonymousObservable.new do |observer|
        found = false
        new_observer = Observer.configure do |o|
          
          o.on_next do |x|
            found = true
            observer.on_next x
          end

          o.on_error {|err| observer.on_error err }

          o.on_completed do 
            observer.on_next(default_value) unless found
            observer.on_completed
          end
        end

        self.subscribe(new_observer)
      end
    end

    # Returns an observable sequence that contains only distinct elements.
    def distinct
      self.distinct_with_key {|x| x}
    end

    # Returns an observable sequence that contains only distinct elements according to the key_selector.
    def distinct_with_key(&key_selector)
      AnonymousObservable.new do |observer|

        h = Hash.new

        new_observer = Observer.configure do |o|

          o.on_next do |x|
            key = nil
            has_added = false

            begin
              key = key_selector.call x
              key_s = key.to_s
              unless h.key? key_s
                has_added = true
                h[key_s] = true
              end
            rescue => e
              observer.on_error e
              return
            end

            observer.on_next x if has_added
          end

          o.on_error {|err| observer.on_error err }
          o.on_completed { on_completed }

        end

        self.subscribe(new_observer)
      end
    end

  end
end
