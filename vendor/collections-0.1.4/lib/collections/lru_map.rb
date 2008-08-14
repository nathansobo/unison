$:.unshift File.dirname(__FILE__)
require 'sequenced_hash'

# = Least Recently Used Map
# Least Recently Used discards the least recently used items first. 
#
# == Description
# A +Map+ implementation with a fixed maximum size which removes
# the least recently used entry if an entry is added when full.
#
# == Usage
#
#--
# (see examples directory under the ruby gems root directory)
#++
#  require 'rubygems'
#  require 'collections'
#  # or
#  require 'collections/lr_map'
#
#  map = LRUMap.new :max_size => 3
#  map[:a] = "a value"
#  map[:b] = "b value"
#  map.full? # => false
#  map.max_size # => 3
#  map.size # => 2
#  map[:c] = "c value"
#  map[:d] = "d value"
#  map.size # => 3
#  map.key?(:a) # => false
#  map.inspect # => {:b=>"b value", :c=>"c value", :d=>"d value"}
#  x = map[:b]
#  map[:f] = "f value"
#  map.inspect # => {:b=>"b value", :d=>"d value", :f=>"f value"}
#
# == Source
# http://code.juretta.com/project/collections/
#
# == Author
#  Stefan Saasen <s@juretta.com>
#
# == Licence
#  MIT
class LRUMap            
  
  DEFAULT_MAX_SIZE = 100
  
  attr_reader :max_size
  
  # map = LRUMap.new # default 100
  # map = LRUMap.new( :max_size => 10000) # Max Size is set to 1000
  def initialize(opts = {})   
    raise ArgumentError unless opts.kind_of?(Hash)
    @max_size = opts[:max_size] ||= DEFAULT_MAX_SIZE
    @__cache = SequencedHash.new
    # Maintains a list of least recently used keys
    @__key_stack = []
  end
  
  # returns true if the _Map_ is full, false otherwise
  def full?
    size >= @max_size
  end                 
  alias :is_full? :full?
  
  # adds a Key-Value pair to the map.
  # If the _Map_ is full the least recently used item is discarded.
  def put(key, val)
    if full?
      # don't retire LRU if you are just
      # updating an existing key
      unless (key?(key))
        # lets retire the least recently used item in the cache
        remove_lru
        raise "Cache too large - this is a bug. Please report to collections+gems@juretta.com" if size > @max_size # Should never happen
      end
    end
    @__cache[key] = val 
    add_to_key_stack key
  end
  alias :[]= :put
  
  # Returns true if the Map contains the _key_
  def key?(key)
     @__cache.key?(key)
  end
  alias :contains_key? :key?
  
  # Returns the _value_ for the _key_
  def get(key)
    val = @__cache[key]
    move_to_mru(key) unless val.nil?
    val
  end
  alias :[] :get
  
  # Returns a new array populated with the keys from this hash. See
  # also +LRUMap#values+.
  def keys
    @__cache.keys
  end

  # Returns a new array populated with the values from _hsh_. See also
  # +LRUMap#keys+.
  def values
    @__cache.values
  end
  
  # Returns the number of elements (key-value pairs) in _Map_
  def size
    @__cache.size
  end
  
  # Return the contents of this _Map_ as a string.
  def inspect
    @__cache.inspect
  end
   

  # ========================== private methods ========================================
  private
  
  # Moves an entry to the MRU position at the end of the list.
  # This implementation moves the updated entry to the end of the list. 
  # 0 - 1 - 2 - 3 - 4
  # LRU           MRU
  def move_to_mru(key)  
    # Remove key from __key_stack
    @__key_stack.delete key
    # Move to Most recently used position at the end of the list
    @__key_stack.push key
  end
  
  def add_to_key_stack(key)
    move_to_mru key
  end
  
  # This method is used internally by the class for 
  # finding and removing the LRU Object.  
  def remove_lru
    key = @__key_stack.shift
    @__cache.delete(key)
  end

end