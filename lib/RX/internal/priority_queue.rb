# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

  class PriorityQueue

    @@length = 0

    attr_reader :length

    def initialize(capacity = 1024)
      @length = 0
      @items = Array.new(capacity)
    end

    def peek
      raise 'Empty PriorityQueue' if @length == 0
      @items[0].value
    end

    def shift
      result = self.peek
      delete_at 0
      result
    end

    def push(item) 
      index = @length
      @length += 1

      @items[index] = IndexedItem.new @@length, item
      @@length += 1
      percolate index
    end

    def delete(item)
      for i in 0..@length
        if @items[i].value == item
          delete_at i
          return true
        end
      end
      return false
    end

    private

    def delete_at(index)
      @length -= 1
      @items[index] = @items[@length]
      @items[@length] = nil
      heapify
    end

    def higher_priority?(left, right)
      @items[left].compare_to(@items[right]) < 0
    end

    def percolate(index)
      return if index > @length || index < 0
      parent = (index - 1) / 2
      return if parent < 0 || parent == index

      if higher_priority? index, parent
        temp = @items[index]
        @items[index] = @items[parent]
        @items[parent] = temp
        percolate parent
      end
    end

    def heapify(index = 0)
      return if index >= @length || index < 0

      left = 2 * index + 1
      right = 2 * index + 2
      first = index

      first = left if left < @length && higher_priority?(left, first)
      first = right if right < @length && higher_priority?(right, first)

      if first != index
        temp = @items[index]
        @items[index] = @items[first]
        @items[first] = temp
        heapify first
      end
    end

    class IndexedItem
      attr_reader :id , :value

      def initialize(id, value)
        @id = id
        @value = value
      end

      def compare_to(other)
        c = @value<=>value
        c = @id<=>other.id if c == 0
        return c
      end
    end

  end
end