# $Id: tc_lru_map_test.rb 100 2006-12-29 11:09:07Z stefan $

# Taken from: http://svn.ruby-lang.org/repos/ruby/tags/v1_8_5_9/test/ruby/test_hash.rb

require File.dirname(__FILE__) + '/test_helper.rb'   

#require 'generator'
 
class MockEntry
   attr_accessor :key, :value
   def initialize(key, value)
     @key, @value = key, value
   end
end

class MockRemoveLRUMap < LRUMap
  
  attr_reader :entry
  
  def remove_lru
    value = @__cache[@__cache.keys.first]
    @entry = MockEntry.new(@__cache.keys.first, value)
    @__cache.delete(@__cache.keys.first)
  end
end
     

class TestLruKeySet < LRUMap
  def keystack
    @__key_stack
  end
end

class TcLRUMapTest < Test::Unit::TestCase
  
  def setup
    @keys = [1, 2, 3, 4, 5, 6, 7, 8]
    @values = ["2A", "2B", "2C",
          "3D", "3E", "3F",
          "4G", "4H"]
  end
  
  def test_initialize
    map = LRUMap.new
    assert_equal 0, map.size
    assert_equal LRUMap::DEFAULT_MAX_SIZE, map.max_size 
    
    map = LRUMap.new :max_size => 10000
    assert_equal 0, map.size
    assert_equal 10000, map.max_size
    
    map = LRUMap.new :max_size => 2345
    assert_equal 0, map.size
    assert_equal 2345, map.max_size      
    
    assert_raise ArgumentError do
      map = LRUMap.new 2345
    end
  end
  
  def test_accessor
    map = LRUMap.new
    assert_equal 0, map.size
    map.put(:a, :b)
    assert_equal 1, map.size
    map[:c] = :d
    assert_equal 2, map.size
    assert_equal :b, map[:a]
  end

  def test_keys_and_values
    map = LRUMap.new
    @keys.each_with_index {|key, i| map[key] = @values[i]}
    assert_equal @keys, map.keys
    assert_equal @values, map.values
  end                       
  
  def test_full?
    map = LRUMap.new :max_size =>2
    assert_equal 0, map.size
    assert_equal 2, map.max_size
    
    map[1] = "v1"
    assert !map.full?
    map[2] = "v2"
    assert map.full?
    
    x = map[1]
    assert_not_nil x
    x = map[2]      
    assert_not_nil x
    assert map.full? 
    
    map[3] = "v3"
    assert_equal 2, map.size
    x = map[3]
    assert_not_nil x
    %w(a b c d).each {|k| map[k] = "val #{k}"}
    assert_equal 2, map.size
  end
  
  def test_internal_key_order
    map = TestLruKeySet.new :max_size => 3
    map[:a] = "va"
    assert_equal [:a], map.keystack
    
    map[:b] = "vb"
    assert_equal [:a, :b], map.keystack
    
    map[:c] = "vc"
    assert_equal [:a, :b, :c], map.keystack
    
    x = map[:b]
    assert_equal [:a, :c, :b], map.keystack
    
    map[:d] = "vd"
    assert_equal [:c, :b, :d], map.keystack
    
    # Keys LRUMap
    assert_equal [:b, :c, :d], map.keys
    
    x = map[:b]
    assert_equal [:c, :d, :b], map.keystack

    # Keys LRUMap
    assert_equal [:b, :c, :d], map.keys
    
    x = map[:c]
    assert_equal [:d, :b, :c], map.keystack
    
    # Keys LRUMap
    assert_equal [:b, :c, :d], map.keys
    
    map[:e] = "ve"
    # Keys LRUMap
    assert_equal [:b, :c, :e], map.keys       
  end
  
  def test_example
    map = LRUMap.new :max_size => 3
    map[:a] = "a value"
    map[:b] = "b value"
    assert !map.full? # => false
    assert_equal 3, map.max_size # => 3
    assert_equal 2, map.size # => 2
    map[:c] = "c value"
    map[:d] = "d value"
    assert_equal 3, map.size # => 3
    assert !map.key?(:a) # => false
    assert_equal '{:b=>"b value", :c=>"c value", :d=>"d value"}', map.inspect # =>
    
    x = map[:b]
    map[:f] = "f value"
    assert_equal '{:b=>"b value", :d=>"d value", :f=>"f value"}', map.inspect
  end
  
  def test_counter
    map = LRUMap.new :max_size => 2
    assert_equal 0, map.size
    assert_equal 2, map.max_size
    vals = [:a, :b, :c, :d, :e, :a, :a, :b]
    # Init Map
    vals.each {|key| map[key] = "val #{key}"}
    assert_equal 2, map.size
    vals.each {|key| map[key]}
    assert_equal 2, map.size
    # Add values to Map
    vals.each {|key| map[key] = "val #{key}"}
    assert_equal 2, map.size
    assert map.key?(:a)
    assert map.key?(:b)
    assert !map.key?(:c)
    assert !map.key?(:d)
  end
                                  
  def test_lru
    map = LRUMap.new :max_size => 4
    map[:a] = "a"
    map[:b] = "b"
    map[:c] = "c"
    assert !map.full?
    map[:d] = "d"
    assert map.full?
    
    map[:e] = "e"
    assert !map.key?(:a)
    
    b = map[:b]  # usage count +1
    map[:f] = "f" # remove :c (count :b > count :c)
    assert map.key?(:b)        
    assert !map.key?(:c)
  end
           
  def test_lru_access_order   
    
    map = LRUMap.new(:max_size => 2)
    assert_equal(0, map.size)
    assert_equal(false, map.full?)
    assert_equal(2, map.max_size)
        
    map.put(@keys[0], @values[0])
    map.put(@keys[1], @values[1])
    # {1=>"2A", 2=>"2B"}
    k = map.keys
    assert_equal(@keys[0], k[0])
    assert_equal(@keys[1], k[1])
    v = map.values
    assert_equal(@values[0], v[0])
    assert_equal(@values[1], v[1])
    
    # no change to order
    map.put(@keys[1], @values[1])
    # {1=>"2A", 2=>"2B"}
    k = map.keys  
    assert_equal(@keys[0], k[0])
    assert_equal(@keys[1], k[1])
    v = map.values
    assert_equal(@values[0], v[0])
    assert_equal(@values[1], v[1])

    # no change to order
    map.put(@keys[1], @values[2])
    k = map.keys
    assert_equal(@keys[0], k[0])
    assert_equal(@keys[1], k[1])
    v = map.values 
    assert_equal(@values[0], v[0])
    assert_equal(@values[2], v[1])
  end
  
  def test_lru_col
    map = LRUMap.new(:max_size => 2)
    assert_equal(0, map.size)
    assert_equal(false, map.full?)
    assert_equal(2, map.max_size)
    
    map.put(@keys[0], @values[0])
    assert_equal(1, map.size)
    assert_equal(false, map.full?)
    assert_equal(2, map.max_size)
    
    map.put(@keys[1], @values[1])
    assert_equal(2, map.size)
    assert_equal(true, map.full?)
    assert_equal(2, map.max_size)

    keys = map.keys 
    assert_equal(@keys[0], keys[0])
    assert_equal(@keys[1], keys[1])

    values = map.values
    assert_equal(@values[0], values[0])
    assert_equal(@values[1], values[1])
    
    map.put(@keys[2], @values[2])
    assert_equal(2, map.size)
    assert_equal(true, map.full?)
    assert_equal(2, map.max_size)
    keys = map.keys
    assert_equal(@keys[1], keys[0])
    assert_equal(@keys[2], keys[1])
    values = map.values
    assert_equal(@values[1], values[0])
    assert_equal(@values[2], values[1])
    
    map.put(@keys[2], @values[0]);
    assert_equal(2, map.size);
    assert_equal(true, map.full?);
    assert_equal(2, map.max_size);
    keys = map.keys    
    assert_equal(@keys[1], keys[0]);
    assert_equal(@keys[2], keys[1]);
    values = map.values 
    assert_equal(@values[1], values[0]);
    assert_equal(@values[0], values[1]);
  
    map.put(@keys[1], @values[3])
    assert_equal(2, map.size)
    assert_equal(true, map.full?)
    assert_equal(2, map.max_size)
  end
  
  def test_remove_lru
    map = MockRemoveLRUMap.new(:max_size => 2)
    assert_nil map.entry
    map.put("A", "a")
    assert_nil map.entry
    map.put("B", "b")
    assert_nil map.entry
    map.put("C", "c");  # removes oldest, which is A=a
    assert_not_nil map.entry
    assert_equal("A", map.entry.key)
    assert_equal("a", map.entry.value)
    assert !map.key?("A")
    assert map.key?("B")
    assert map.key?("C")
  end
  
end