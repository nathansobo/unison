#!/usr/bin/env ruby
#
#  Created by Stefan Saasen on 2006-12-29.
#  Copyright (c) 2006. All rights reserved.

require 'rubygems'
#  require 'collections'
#  # or
require 'collections/lru_map'
map = LRUMap.new :max_size => 3
map[:a] = "a value"
map[:b] = "b value"
map.full? # => false
map.max_size # => 3
map.size # => 2
map[:c] = "c value"
map[:d] = "d value"
map.size # => 3
map.key?(:a) # => false
puts map.inspect # => {:b=>"b value", :c=>"c value", :d=>"d value"}
x = map[:b]
map[:f] = "f value"
puts map.inspect # => {:b=>"b value", :d=>"d value", :f=>"f value"}
