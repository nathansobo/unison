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

      def relates_to_n(name, &proc)
        instance_relations[name] = proc
        attr_reader name
      end

      def find(id)
        relation.where(relation[:id].eq(id)).first
      end

      def create(attributes)
        relation.insert(new(attributes))
      end

      protected
      def instance_relations
        @instance_relations ||= Hash.new
      end
    end

    def self.included(a_module)
      a_module.extend ClassMethods
    end

    attr_reader :attributes, :nested_tuples

    def initialize(*args)
      if attributes_hash?(args)
        @primitive = true
        @attributes = {}
        args.first.each do |attribute, value|
          self[attribute] = value
        end
      else
        @primitive = false
        @nested_tuples = args
      end
      instance_relations.each do |name, proc|
        relation = instance_eval(&proc)
        instance_variable_set("@#{name}", relation)
      end
    end
    
    def relation
      self.class.relation
    end

    def primitive?
      @primitive
    end

    def compound?
      !primitive?
    end

    def [](attribute)
      if primitive?
        attributes[attribute_for(attribute)]
      else
        nested_tuples.each do |tuple|
          return tuple if tuple.relation == attribute
          return tuple[attribute] if tuple.relation.has_attribute?(attribute)
        end
        raise "Attribute #{attribute} not found"
      end
    end

    def []=(attribute, value)
      attributes[attribute_for(attribute)] = value
    end

    def ==(other)
      if primitive?
        attributes == other.attributes
      else
        nested_tuples == other.nested_tuples
      end
    end

    def bind(expression)
      case expression
      when Attribute
        self[expression]
      else
        expression
      end
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

    def attributes_hash?(args)
      args.size == 1 && args.first.instance_of?(Hash)
    end

    def instance_relations
      self.class.send(:instance_relations)
    end
  end
end