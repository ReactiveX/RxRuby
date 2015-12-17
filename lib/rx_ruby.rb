# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

$:.unshift File.dirname(__FILE__) # For use/testing when no gem is installed

# Require all of the Ruby files in the given directory.
#
# path - The String relative path from here to the directory.
#
# Returns nothing.
def require_all(path)
  glob = File.join(File.dirname(__FILE__), path, '*.rb')
  Dir[glob].sort.each do |f|
    require f
  end
end

require_all 'rx_ruby/internal/'
require_all 'rx_ruby/concurrency/'
require_all 'rx_ruby/subscriptions/'
require_all 'rx_ruby/core/'
require_all 'rx_ruby/linq/'
require_all 'rx_ruby/linq/observable/'
require_all 'rx_ruby/operators'
require_all 'rx_ruby/subjects'
require_all 'rx_ruby/testing'
require_all 'rx_ruby/joins'
