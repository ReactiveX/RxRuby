# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'singleton'
require 'thread'
require 'rx/concurrency/local_scheduler'
require 'rx/disposables/disposable'
require 'rx/disposables/single_assignment_disposable'
require 'rx/disposables/composite_disposable'

module RX

    # Represents an object that schedules units of work on the platform's default scheduler.
    class CurrentThreadScheduler < RX::LocalScheduler

    	include Singleton



    end

end