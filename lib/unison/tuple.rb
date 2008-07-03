module Unison
  module Tuple
    module ClassMethods
      attr_accessor :relation

      def member_of(relation)
        @relation = relation
        relation.tuple_class = self
      end

      def attribute(name)
        relation.attribute(name)
      end

      def [](attribute)
        relation[attribute]
      end

      def where(predicate)
        relation.where(predicate)
      end

      def relates_to_n(name, &block)
        define_method name, &block
      end

      def find(id)
        relation.where(relation[:id].eq(id)).first
      end
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