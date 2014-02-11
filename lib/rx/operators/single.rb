# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/core/observer'
require 'rx/core/observable'

module RX

  module Observable

    # Hides the identity of an observable sequence.
    def as_observable
      AnonymousObservable.new &subscribe
    end

    # Projects each element of an observable sequence into zero or more buffers which are produced based on element count information.
    def buffer_with_count(count, skip = count)
      # TODO: window and select_many
    end

  end
end