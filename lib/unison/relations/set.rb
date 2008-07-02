module Unison
  class Set
    attr_reader :name, :attributes, :tuple_class, :tuples
    
    def initialize(name)
      @name = name
      @attributes = []
      @tuple_class = Class.new(Tuple::Base)
      tuple_class.relation = self
      @tuples = []
    end

    def attribute(name)
      attributes.push(Attribute.new(self, name))
    end

    def [](attribute_name)
      attributes.detect {|attribute| attribute.name == attribute_name}
    end

    def insert(tuple)
      tuples.push(tuple)
    end
  end
end