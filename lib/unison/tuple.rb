module Unison
  module Tuple
    module ClassMethods
      attr_accessor :relation
    end

    def self.included(a_module)
      a_module.extend ClassMethods
    end

    attr_reader :attributes

    def initialize(attributes)
      @attributes = {}
      attributes.each do |attribute, value|
        self[attribute] = value
      end
    end
    
    def relation
      self.class.relation
    end

    def [](attribute)
      attributes[attribute_for(attribute)]
    end

    def []=(attribute, value)
      attributes[attribute_for(attribute)] = value
    end

    class Base
      include Tuple
    end

    protected
    def attribute_for(attribute_or_name)
      case attribute_or_name
      when Attribute
        attribute_or_name
      when Symbol
        relation[attribute_or_name]
      else
        raise "Attributes must be Attributes or Symbols"
      end
    end

  end
end