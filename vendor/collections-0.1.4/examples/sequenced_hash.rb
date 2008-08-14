#!/usr/bin/env ruby
#
#  Created by Stefan Saasen on 2006-12-29.
#  Copyright (c) 2006. All rights reserved.

require 'rubygems'
#  require 'collections'
#  # or
require 'collections/sequenced_hash'
hash = SequencedHash.new
hash[:v1] = "v1"
hash[:v2] = "v2"
hash[:v3] = "v3"
puts hash.inspect # => {:v1=>"v1", :v2=>"v2", :v3=>"v3"}
puts hash.at(0) # => "v1"
puts hash.at(1) # => "v2"
