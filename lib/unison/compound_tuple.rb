module Unison
  module CompoundTuple
    module ClassMethods
      attr_accessor :relation
    end

    def self.included(a_module)
      a_module.extend(ClassMethods)
    end

    attr_reader :tuples
    def initialize(*tuples)
      @tuples = tuples
    end

    def [](attribute)
      tuples.each do |tuple|
        return tuple[attribute] if tuple.relation.has_attribute?(attribute)
      end
      raise "Attribute #{attribute} not found"
    end

    class Base
      include CompoundTuple
    end
  end
  
end