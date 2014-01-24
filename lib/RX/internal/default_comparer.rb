# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

	# Default comparer to compare two objects.  
	class DefaultComparer

		# Compares two objects. If x > y then 1 else if y > x -1 else 0
		def compare(x, y)
			if x > y
				return 1
			elsif x < y
				return -1
			else
				return 0
			end
					
		end

	end
end