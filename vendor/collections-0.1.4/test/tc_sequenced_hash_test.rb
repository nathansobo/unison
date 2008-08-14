# $Id: tc_sequenced_hash_test.rb 111 2007-07-27 12:26:45Z stefan $

# Taken from: http://svn.ruby-lang.org/repos/ruby/tags/v1_8_5_9/test/ruby/test_hash.rb

require File.dirname(__FILE__) + '/test_helper.rb'   

#require 'generator'

class TcSequencedHashTest < Test::Unit::TestCase 
  
  def setup
    @seq_hash = SequencedHash.new
    @elements = (0..2000)
    @elements.each do |i|
      @seq_hash["k#{i}"] = "Value #{i}"
    end
  end          
  
  def test_delete_if
    h = SequencedHash.new 
    h["a"] = 100
    h["b"] = 200 
    h["c"] = 300
    c = h.delete_if {|key, value| key >= "b" }   #=> {"a"=>100}
    assert_equal 1, c.size
    assert_equal 1, c.keys.size
    assert_equal 100, c["a"]
  end
  
  def test_delete_if_2  
    test = @seq_hash.delete_if {|key, value| key.gsub(/k/, "").to_i >= 1000}
    assert_equal 1000, test.size
  end
  
  def test_size_length
    assert_equal @elements.max+1, @seq_hash.size
    assert_equal @elements.max+1, @seq_hash.size
  end                             
  
  def test_clear
    assert @seq_hash.size > 0
    @seq_hash.clear
    assert_equal 0, @seq_hash.size
  end
  
  def test_kind_of
    assert @seq_hash.kind_of?(Hash)
    assert @seq_hash.is_a?(Hash)
    assert !@seq_hash.instance_of?(Hash) 
    assert @seq_hash.instance_of?(SequencedHash) 
  end
  
  def test_empty
    assert !@seq_hash.empty?
  end
                            
  def test_default
    default = "no val"
    h = SequencedHash.new(default)
    assert_equal default, h[3]
    assert_equal default, h[:no_key_exists]
    
    h = SequencedHash.new {|hash, key| key.respond_to?(:to_str) ? key.to_s.upcase : nil}
    assert_equal "HALLO", h["hallo"]
    assert_equal nil, h[4]
    
    h = SequencedHash.new 0
    assert_equal 0, h[1]
  end                    
  
  def test_delete
    h = SequencedHash.new
    h[:key] = "a value"
    assert_equal 1, h.size
    h.delete(:key)
    assert_equal 0, h.size
  end

  def test_rehash
    h = SequencedHash.new
    c = [20,5]
    h[c] = "a place"
    assert_equal "a place", h[c]
    c << 100
    assert_equal h[c], nil
    h.rehash
    assert_equal "a place", h[c]
  end
                               
  def test_keys
    assert_equal @elements.to_a.collect{|k| "k#{k}"}, @seq_hash.keys
  end          
  
  def test_values
    assert_equal @elements.to_a.collect{|k| "Value #{k}"}, @seq_hash.values
  end            
  
  def test_each
    keys = @elements.to_a.collect{|k| "k#{k}"}
    values = @elements.to_a.collect{|k| "Value #{k}"}
    @seq_hash.each do |k,v|
      assert_equal keys.shift, k
      assert_equal values.shift, v
    end
    assert_equal 0, keys.size
    assert_equal 0, values.size
  end
  
  def test_each_pair
    keys = @elements.to_a.collect{|k| "k#{k}"}
    values = @elements.to_a.collect{|k| "Value #{k}"}
    @seq_hash.each_pair do |k,v|
      assert_equal keys.shift, k
      assert_equal values.shift, v
    end
    assert_equal 0, keys.size
    assert_equal 0, values.size
  end  
  
  def test_delete
    h = SequencedHash.new
    h[:a] = "no"
    h[:b] = "2"
    h[:c] = " asdhfjk asdjkfh asjdhfajksdhf kajlsdf"
    h[:d] = "28347 23984 723984 2894729834 7"
    h[:e] = "A fox"
    h[:f] = "nox noctis"

    assert h.key?(:a)
    assert_equal 6, h.size
    h.delete(:a)
    assert !h.key?(:a)
    
    assert h.key?(:b)
    assert_equal 5, h.size
    h.delete(:b)
    assert !h.contains_key?(:b)
    assert_equal 4, h.size
    assert_equal '{:c=>" asdhfjk asdjkfh asjdhfajksdhf kajlsdf", :d=>"28347 23984 723984 2894729834 7", :e=>"A fox", :f=>"nox noctis"}', h.inspect
  end
  
  def test_grep
    h = SequencedHash.new
    h[:a] = "no"
    h[:b] = "2"
    h[:c] = " asdhfjk asdjkfh asjdhfajksdhf kajlsdf"
    h[:d] = "28347 23984 723984 2894729834 7"
    h[:e] = "A fox"
    h[:f] = "nox noctis"
    
    assert_equal [[:e, "A fox"]], h.grep(/fox/)
    assert_equal [[:e, "A fox"], [:f, "nox noctis"]], h.grep(/(f|n)ox/)    
    assert_equal ["A FOX", "NOX NOCTIS"], h.grep(/(f|n)ox/) {|kv| kv.last.upcase if kv.last.respond_to?(:upcase)}
    
    
    h = SequencedHash.new
    h["guitar"] = "Paul Reed Smith"
    h["computer"] = "Mac Book Pro"
    h["car"] = "Land Rover Defender"
    h["ski"] = "Rossignol"
    h["chute"] = "Electrar 170"
    
    assert_equal [["guitar", "Paul Reed Smith"], ["chute", "Electrar 170"]], h.grep(/(t|r)ar/)
  end                                                      

  def test_each_key
    keys = @elements.to_a.collect{|k| "k#{k}"}
    @seq_hash.each_key do |k|
      assert_equal keys.shift, k
    end
    assert_equal 0, keys.size
  end

  def test_each_value
    values = @elements.to_a.collect{|k| "Value #{k}"}
    @seq_hash.each_value do |v|
      assert_equal values.shift, v
    end
    assert_equal 0, values.size
  end

  def test_to_a
    soll = @elements.to_a.collect{|k| ["k#{k}", "Value #{k}"]}
    assert_equal soll, @seq_hash.to_a
  end

  def test_last
    assert_equal "Value 2000", @seq_hash.last
    assert_equal ["Value 1997", "Value 1998", "Value 1999", "Value 2000"], @seq_hash.last(4)
    
    assert_equal nil, SequencedHash.new.last
    assert_equal [], SequencedHash.new.last(5)    
  end

  def test_first
    assert_equal "Value 0", @seq_hash.first  
    assert_equal ["Value 0", "Value 1", "Value 2", "Value 3"], @seq_hash.first(4)
    
    assert_equal nil, SequencedHash.new.first
    assert_equal [], SequencedHash.new.first(5)
  end
  
  def test_inspect
    soll = /^\{\"k0\"=>\"Value 0\", \"k1\"=>\"Value 1\", \"k2\"=>\"Value 2\", \"k3\"=>\"Value 3\", \"k4\"=>\"Value 4\"/
    assert_match soll, @seq_hash.inspect
  end
  
  def test_select
    h = SequencedHash.new
    h["a"] = 400
    h["b"] = 200
    h["c"] = 300 
    h["d"] = 100 
    h["e"] = 10
    h["f"] = 25
    h["g"] = 0
    
    assert_equal [["b", 200], ["c", 300], ["d", 100], ["e", 10], ["f", 25], ["g", 0]], h.select {|k,v| k > "a"}
    assert_equal [["a", 400], ["b", 200], ["c", 300]], h.select {|k,v| v > 100}  #=> [["a", 100]]    
  end                                            
  
  def test_invert
    keys = @elements.to_a.collect{|k| "k#{k}"}
    values = @elements.to_a.collect{|k| "Value #{k}"}
    @seq_hash.invert.each do |k,v|
      assert_equal keys.shift, v  # !
      assert_equal values.shift, k # !
    end
    assert_equal 0, keys.size
    assert_equal 0, values.size
  end
  
  def test_sequence_1
    assert_equal "Value 100", @seq_hash.at(100)
  end
  
  def test_sequence_2
    h = SequencedHash.new
    h['b'] = 1
    h['a'] = 2
    h['c'] = 3
    assert_equal ['b', 'a', 'c'], h.keys
    assert_equal [1, 2, 3], h.values
    h['a'] = 4
    assert_equal ['b', 'a', 'c'], h.keys
    assert_equal [1, 4, 3], h.values
  end
  
  def test_equality
    h = SequencedHash.new
    h['b'] = 1
    h['a'] = 2
    h['c'] = 3
    
    h2 = SequencedHash.new
    h2['b'] = 1
    h2['a'] = 2
    h2['c'] = 3    
    
    assert h == h2
    assert h.eql?(h2)
    assert !h.equal?(h2)
  end
  
  # Bugfix test
  # Bug #12019 reported by Dan Kirkwood
  def test_bug_12019
    h = SequencedHash.new
    assert_nothing_raised(SystemStackError) { h == 1 }
    assert !(h == 1)
  end  
  
  def test_hash
    x = {1=>2, 2=>4, 3=>6}
    y = {1, 2, 2, 4, 3, 6}

    assert_equal(2, x[1])

    assert(begin
         for k,v in y
           raise if k*2 != v
         end
         true
       rescue
         false
       end)

    assert_equal(3, x.length)
    assert(x.has_key?(1))
    assert(x.has_value?(4))
    assert_equal([4,6], x.values_at(2,3))
    assert_equal({1=>2, 2=>4, 3=>6}, x)

    z = y.keys.join(":")
    assert_equal("1:2:3", z)

    z = y.values.join(":")
    assert_equal("2:4:6", z)
    assert_equal(x, y)

    y.shift
    assert_equal(2, y.length)

    z = [1,2]
    y[z] = 256
    assert_equal(256, y[z])

    x = SequencedHash.new(0)
    x[1] = 1
    assert_equal(1, x[1])
    assert_equal(0, x[2])

    x = SequencedHash.new([])
    assert_equal([], x[22])
    assert_same(x[22], x[22])

    x = SequencedHash.new{[]}
    assert_equal([], x[22])
    assert_not_same(x[22], x[22])

    x = SequencedHash.new{|h,k| z = k; h[k] = k*2}
    z = 0
    assert_equal(44, x[22])
    assert_equal(22, z)
    z = 0
    assert_equal(44, x[22])
    assert_equal(0, z)
    x.default = 5
    assert_equal(5, x[23])

    x = SequencedHash.new
    def x.default(k)
      $z = k
      self[k] = k*2
    end
    $z = 0
    assert_equal(44, x[22])
    assert_equal(22, $z)
    $z = 0
    assert_equal(44, x[22])
    assert_equal(0, $z)
  end
  
  def test_enumerable
     s = SequencedHash.new
     s[1] = "eins"
     s[2] = "zwei"
     s[3] = "drei"
     assert s.respond_to?(:each_with_index)
     assert s.respond_to?(:include?)
     s.each_with_index do |elem, i|          
       assert elem.kind_of?(Array)
       assert i < 3
     end
     assert s.include?(1)
     assert !s.include?(5)
     assert_equal [[3, "drei"]], s.grep(/re/)
     assert_equal [[1, "eins"], [2, "zwei"], [3, "drei"]], s.grep(/ei/)
  end
end
        