# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx'

describe RX::SingleAssignmentDisposable do 

	describe '#disposable' do
		it 'should allow null for disposable' do
			d = RX::SingleAssignmentDisposable.new
			d.disposable = nil

			expect(d.disposable).to be_nil
		end
	end
	
end