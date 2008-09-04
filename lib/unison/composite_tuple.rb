module Unison
  class CompositeTuple
    include Tuple
    attr_reader :nested_tuples
    retain :nested_tuples

    def initialize(*nested_tuples)
      super()
      @nested_tuples = nested_tuples
    end

    def [](attribute)
      nested_tuples.each do |tuple|
        return tuple[attribute] if tuple.has_attribute?(attribute)
      end
      raise ArgumentError, "Attribute #{attribute} not found"
    end

    def has_attribute?(attribute)
      nested_tuples.each do |tuple|
        return true if tuple.has_attribute?(attribute)
      end
      false
    end    

    def ==(other)
      return false unless other.is_a?(CompositeTuple)
      nested_tuples == other.nested_tuples
    end

    def primitive?
      false
    end

    def compound?
      true
    end
  end
end