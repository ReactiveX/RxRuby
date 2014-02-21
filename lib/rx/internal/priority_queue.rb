# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

  # Priority Queue implemented as a binary heap.
  class PriorityQueue
    def initialize
      @items = []
      @mutex = Mutex.new
    end

    def peek
      @mutex.synchronize do
        unsafe_peek
      end
    end

    def shift
      @mutex.synchronize do
        result = unsafe_peek
        delete_at 0
        result
      end
    end

    def push(item)
      @mutex.synchronize do
        @items.push IndexedItem.new(item)
        percolate length - 1
      end
    end

    def delete(item)
      @mutex.synchronize do
        index = @items.index {|it| it.value == item }
        if index
          delete_at index
          true
        else
          false
        end
      end
    end

    def length
      @items.length
    end

    private

    def unsafe_peek
      raise 'Empty PriorityQueue' if length == 0
      @items.first.value
    end

    def delete_at(index)
      substitute = @items.pop
      if substitute and index < @items.length
        @items[index] = substitute
        heapify index
      end
    end

    # bubble up an item while it's smaller than parents
    def percolate(index)
      parent = (index - 1) / 2
      return if parent < 0

      current_value = @items[index]
      parent_value  = @items[parent]

      if current_value < parent_value
        @items[index]  = parent_value
        @items[parent] = current_value
        percolate parent
      end
    end

    # bubble down an item while it's bigger than children
    def heapify(index)
      current_index = index
      left_index    = 2 * index + 1
      right_index   = 2 * index + 2

      current_value = @items[index]
      left_value    = @items[left_index]
      right_value   = @items[right_index]

      if right_value && right_value < current_value && right_value < left_value
        current_index = right_index
      elsif left_value && left_value < current_value
        current_index = left_index
      end

      if current_index != index
        @items[index] = @items[current_index]
        @items[current_index] = current_value
        heapify current_index
      end
    end

    class IndexedItem
      include Comparable
      attr_reader :id , :value

      @@length = 0

      def initialize(value)
        @id = @@length += 1
        @value = value
      end

      def <=>(other)
        if @value == other.value
          @id <=> other.id
        else
          @value <=> other.value
        end
      end
    end

  end
end
