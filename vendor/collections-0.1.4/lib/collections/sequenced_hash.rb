# = SequencedHash
#
# == Version
#  $Revision: 111 $
#
# == Description
# A Map of objects whose mapping entries are sequenced based on the 
# order in which they were added.
# 
# SequencedHash extends Hash so every method available in Hash is available here too!
# 
# == Usage
#
#--
# (see examples directory under the ruby gems root directory)
#++
#  require 'rubygems'
#  require 'collections'
#  # or
#  require 'collections/sequenced_hash'
#  hash = SequencedHash.new
#  hash[:v1] = "v1"
#  hash[:v2] = "v2"
#  hash[:v3] = "v3"
#  hash.inspect # => {:v1=>"v1", :v2=>"v2", :v3=>"v3"}
#  hash.at(0) # => "v1"
#  hash.at(1) # => "v2"
#
# == Source
# http://code.juretta.com/project/collections/
#
# == Author
#  Stefan Saasen <s@juretta.com>
#
# == Licence
#  MIT
class SequencedHash < Hash
  
  attr_reader :seq
  
  # SequencedHashes have a <em>default value</em> that is returned when accessing
  # keys that do not exist in the hash. By default, that value is
  #  nil
  #  Hash.new                          => hash
  #  Hash.new(obj)                     => aHash
  #  Hash.new {|hash, key| block }     => aHash
  def initialize(*default, &block)
    @seq = Array.new                   
    super
  end  
  
  def keys
    @seq
  end
  
  def values
    @seq.collect {|key| self[key]}
  end
  
  # Calls *block* once for each key in SequencedHash, passing the key and value as parameter.
  def each
    @seq.each {|k| yield k, self[k]} 
  end
  alias :each_pair :each
  
  def <=>(other)
    raise NotImplementedError
  end
  
  # Equality---At the +Object+ level, +==+ returns +true+ only if _obj_
  # and _other_ are the same object. Typically, this method is
  # overridden in descendent classes to provide class-specific meaning.
  #
  # Unlike +==+, the +equal?+ method should never be overridden by
  # subclasses: it is used to determine object identity (that is,
  # +a.equal?(b)+ iff +a+ is the same object as +b+).
  #
  # The +eql?+ method returns +true+ if _obj_ and _anObject_ have the
  # same value. Used by +Hash+ to test members for equality. For
  # objects of class +Object+, +eql?+ is synonymous with +==+.
  # Subclasses normally continue this tradition, but there are
  # exceptions. +Numeric+ types, for example, perform type conversion
  # across +==+, but not across +eql?+, so:
  #
  #  1 == 1.0     #=> true
  #  1.eql? 1.0   #=> false
  def eql?(other)
    return false if @seq != other.seq
    self == other            
  end
  
  def == other
    return super unless other.is_a?(SequencedHash)
    return false if @seq != other.seq
    super other
  end  
  
  # Returns a nested array with _key_, _value_ pairs for which +Pattern ===
  # key+ or +Pattern === value+. If the optional _block_ is supplied, each matching
  # key, value pair (as an array) is passed to it, and the block's result is stored in the
  # output array. 
  #
  #  hash = SequencedHash.new
  #  hash["guitar"] = "Paul Reed Smith"
  #  hash["computer"] = "Mac Book Pro"
  #  hash["car"] = "Land Rover Defender"
  #  hash["ski"] = "Rossignol"
  #  hash["chute"] = "Electrar 170"
  #  h.grep(/(t|r)ar/)  # => [["guitar", "Paul Reed Smith"], ["chute", "Electrar 170"]]
  #
  #  hash.grep(pattern)                   => array
  #  hash.grep(pattern) {| obj | block }  => array
  def grep(pattern)
    values = inject([]) do |ary, kv|
      ary << kv if kv.first =~ pattern || kv.last =~ pattern
      ary
    end
    if block_given?
      values.map {|elem| yield elem}
    else
      #self.values.grep(pattern)
      values
    end
  end
  
  # Calls *block* for each key in SequencedHash, passing the key as the parameter.
  def each_key
    @seq.each {|k| yield k} 
  end
  
  # Calls *block* for each key in SequencedHash, passing the value as the parameter.  
  def each_value
    @seq.each {|k| yield self[k]}
  end       
  
  
  # Element assignment - Associates the value given by *value* with the key given by *key*
  def store(key, value)
    @seq << key unless has_key? key # Oder Set nehmen?
    super
  end
  alias :put :store
  alias :add :store
  alias :[]= :store
  
  # Returns the element at _index_. A negative index counts from the
  # end of _self_. Returns +nil+ if the index is out of range.
  def at(position)
    key = @seq.at(position)
    self[key]
  end
  
  # Returns a new array consisting of +[key,value]+ pairs for which the
  # block returns true. Also see +Hash.values_at+.
  # 
  #  h = SequencedHash.new
  #  h["a"] = 100
  #  h["b"] = 200
  #  h["c"] = 300
  #
  #  h.select {|k,v| k > "a"}  #=> [["b", 200], ["c", 300]]
  #  h.select {|k,v| v < 200}  #=> [["a", 100]]
  def select
    super # no need to overwrite...
  end
                                   
  # Returns a new _SequencedHash_ created by using _SequencedHash_'s values as keys, and the
  # keys as values.
  def invert
    @seq.inject(SequencedHash.new){ |hash, k| hash[self[k]] = k; hash }
  end

  def inspect
    '{' + self.to_a.map{|elem| elem.first.inspect + '=>' + elem.last.inspect }.join(', ') + '}'
  end
  
  # Removes all key/value pairs from SequencedHash
  def clear
    @seq.clear
    super
  end
  
  # Converts _SequencedHash_ to a nested array of +[+ _key, value_ +]+ arrays.
  def to_a
    @seq.map{|k| [k, self[k]]}
  end
  
  # Returns the first element, or the first +n+ elements, of the array.
  # If the array is empty, the first form returns +nil+, and the second
  # form returns an empty array.
  def first(n = nil)
    return self[@seq.first] if n.nil?
    # Returns the first _n_ elements of self
    @seq.first(n).collect{|k| self[k]}
  end
  
  # Returns the last element(s) of _self_. If the array is empty, the
  # first form returns +nil+.
  def last(n=nil)
    return self[@seq.last] if n.nil?
    # Returns the first _n_ elements of self
    @seq.last(n).collect{|k| self[k]}
  end
  
  # Deletes and returns a key-value pair from _hsh_ whose key is equal
  # to _key_. If the key is not found, returns the _default value_. If
  # the optional code block is given and the key is not found, pass in
  # the key and return the result of _block_.                          
  def delete(key)
    @seq.delete(key)
    super
  end           
  
  # Deletes every key-value pair from _hsh_ for which _block_ evaluates
  # to +true+.
  #
  #  h = { "a" => 100, "b" => 200, "c" => 300 }
  #  h.delete_if {|key, value| key >= "b" }   #=> {"a"=>100}
  def delete_if(&block)
    @seq.clone.each{|k| self.delete(k) if yield(k, self[k])}
    self
  end
  
  alias :contains_key? :key?
  
end
