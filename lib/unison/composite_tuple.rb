module Unison
  module CompositeTuple
    include Tuple
    attr_reader :nested_tuples

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

    class Base
      include CompositeTuple
    end

    protected
    def after_first_retain
      nested_tuples.each do |tuple|
        tuple.retained_by(self)
      end
    end

    def after_last_release
      nested_tuples.each do |tuple|
        tuple.release(self)
      end
    end
  end
end