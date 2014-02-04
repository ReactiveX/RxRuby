# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

  # Provides a set of static methods for creating subjects.
  class Subject

    # Creates a subject from the specified observer and observable.
    def self.create(observer, observable)
      AnonymousSubject.new(observer, observable)
    end

    class AnonymousSubject
      include Observable
      include Observer

      def initialize(observer, observable)
        @observer = observer
        @observable = observable
      end

      def on_completed
        @observer.on_completed
      end

      def on_error(error)
        raise 'error cannot be nil' unless error
        @observer.on_error(error)
      end

      def on_next(value)
        @observer.on_next(value)
      end

      def subscribe(observer)
        raise 'observer cannot be nil' unless observer
        @observable.subscribe(observer)
      end
    end

  end
end