# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

	class PriorityQueue

		@@count = 0

		attr_reader :length

		def initialize(capacity = 1024)
			@length = 0
			@items = Array.new(capacity)
		end

		def peek
			raise Exception.new 'Empty PriorityQueue' if @length == 0
			@items[0].value
		end

		def shift
			result = self.peek
			self.remove_at 0
			result
		end

		def push(item) 
			index = @length
			@length += 1

			@items[index] = IndexedItem.new @@count, item
			@count += 1
			self.percolate index
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

			if self.higher_priority? index, parent
				temp = @items[index]
				@items[index] = @items[parent]
				@items[parent] = temp
				self.percolate parent
			end
		end

		def heapify(index = 0)
			return if index >= @length || index < 0

			left = 2 * index + 1
			right = 2 * index + 2
			first = index

			first = left if left < @length && higher_priority? left, first
			first = right if right < @length && higher_priority? right, first

			if first != index
				temp = @items[index]
				@items[index] = @items[first]
				@items[first] = temp
				self.heapify first
			end
		end

	end
end