module Unison
  module CompoundTuple
    include Tuple

    module ClassMethods
      include Tuple::ClassMethods
    end
    def self.included(a_module)
      a_module.extend ClassMethods
    end

    def initialize(*nested_tuples)
      super()
      @nested_tuples = nested_tuples
    end

    def [](attribute)
      nested_tuples.each do |tuple|
        return tuple if tuple.relation == attribute
        return tuple[attribute] if tuple.relation.has_attribute?(attribute)
      end
      raise ArgumentError, "Attribute #{attribute} not found"
    end

    def ==(other)
      return false unless other.is_a?(CompoundTuple)
      nested_tuples == other.nested_tuples
    end

    def primitive?
      false
    end

    def compound?
      true
    end

    public
    class Base
      include CompoundTuple
    end
  end
end