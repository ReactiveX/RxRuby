# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

  # Time based operations
  module Observable

    # Projects each element of an observable sequence into consecutive non-overlapping buffers which are produced
    # based on timing information.
    def buffer_with_time(time_span)
      raise ArgumentError.new 'time_span cannot be less than zero' if time_span < 0

    end

  end

end