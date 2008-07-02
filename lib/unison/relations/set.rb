module Unison
  class Set
    attr_reader :name, :attributes
    
    def initialize(name)
      @name = name
      @attributes = []
    end

    def attribute(name)
      attributes.push(Attribute.new(self, name))
    end
  end
end