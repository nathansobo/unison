module Unison
  module Relations
    class Set < Relation
      attr_reader :name, :attributes

      def initialize(name)
        super()
        @name = name
        @attributes = SequencedHash.new
      end

      def tuple_class
        @tuple_class ||= begin
          tuple_class = Class.new(Unison::PrimitiveTuple)
          tuple_class.set = self
          tuple_class
        end
      end
      attr_writer :tuple_class

      def add_primitive_attribute(name, type, &transform)
        if attributes[name]
          if attributes[name].type == type
            attributes[name]
          else
            raise ArgumentError, "Attribute #{name} already exists with type #{attributes[name].inspect}. You tried to change the type to #{type.inspect}, which is an illegal operation."
          end
        else
          attributes[name] = Attributes::PrimitiveAttribute.new(self, name, type, &transform)
        end
      end

      def add_synthetic_attribute(name, &definition)
        if attributes[name]
          raise ArgumentError, "Attribute #{name} already exists."
        else
          attributes[name] = Attributes::SyntheticAttribute.new(self, name, &definition)
        end
      end

      def has_attribute?(candidate_attribute)
        case candidate_attribute
        when Set
          return self == candidate_attribute
        when Attributes::Attribute
          attribute = attributes[candidate_attribute.name]
          attribute == candidate_attribute
        when Symbol
          attributes[candidate_attribute] ? true : false
        end
      end

      def has_synthetic_attribute?(candidate_attribute)
        case candidate_attribute
        when Attributes::SyntheticAttribute
          attributes.detect {|name, attribute| candidate_attribute == attribute}
        when Symbol
          (attributes[candidate_attribute] && attributes[candidate_attribute].is_a?(Attributes::SyntheticAttribute)) ? true : false
        when Attributes::PrimitiveAttribute
          false
        else
          raise ArgumentError, "#{candidate_attribute.inspect} is not a SyntheticAttribute or Symbol."
        end
      end

      def attribute(attribute_name)
        attributes[attribute_name] ||
          raise(ArgumentError, "Attribute with name #{attribute_name.inspect} is not defined on Set with name #{name.inspect}.")
      end

      def primitive_attributes
        attributes.values.find_all do |attribute|
          attribute.is_a?(Attributes::PrimitiveAttribute)
        end
      end

      def synthetic_attributes
        attributes.values.find_all do |attribute|
          attribute.is_a?(Attributes::SyntheticAttribute)
        end
      end

      def compound?
        false
      end

      def set
        self
      end

      def composed_sets
        [self]
      end

      def insert(tuple)
        raise "Relation must be retained" unless retained?
        raise ArgumentError, "Passed in PrimitiveTuple's #set must be #{self}" unless tuple.set == self
        if find(tuple[:id])
          raise ArgumentError, "Tuple with id #{tuple[:id]} already exists in this Set"
        end
        tuples.push(tuple)
        tuple.send(:after_create) if tuple.new?
        insert_subscription_node.call(tuple)
        tuple
      end

      def delete(tuple)
        raise ArgumentError, "Tuple: #{tuple.inspect}\nis not in the set" unless tuples.include?(tuple)
        tuples.delete(tuple)
        delete_subscription_node.call(tuple)
        tuple
      end

      def merge(tuples)
        tuples.each do |tuple|
          insert(tuple) unless find(tuple[:id])
        end
      end

      def default_foreign_key_name
        @default_foreign_key_name ||= :"#{name.to_s.singularize.to_s.underscore}_id"
      end
      attr_writer :default_foreign_key_name

      def to_arel
        @arel ||= Arel::Table.new(name, Adapters::Arel::Engine.new(self))
      end

      def inspect
        "<#{self.class}:#{object_id} @name=#{name.inspect}>"
      end

      def notify_tuple_update_subscribers(tuple, attribute, old_value, new_value)
        tuple_update_subscription_node.call(tuple, attribute, old_value, new_value)
      end

      protected
      attr_reader :signals

      def initial_read
        []
      end
    end
  end
end