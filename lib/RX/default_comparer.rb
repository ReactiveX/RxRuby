# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module RX

	class DefaultComparer

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