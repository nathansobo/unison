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
          tuple_class = Class.new(Unison::PrimitiveTuple::Base)
          tuple_class.relation = self
          tuple_class
        end
      end
      attr_writer :tuple_class

      def has_attribute(name, type)
        if attributes[name]
          if attributes[name].type == type
            attributes[name]
          else
            raise ArgumentError, "Attribute #{name} already exists with type #{attributes[name].inspect}. You tried to change the type to #{type.inspect}, which is an illegal operation."
          end
        else
          attributes[name] = Attribute.new(self, name, type)
        end
      end

      def has_attribute?(candidate_attribute)
        case candidate_attribute
        when Set
          return self == candidate_attribute
        when Attribute
          attributes.detect {|name, attribute| candidate_attribute == attribute}
        when Symbol
          attributes[candidate_attribute] ? true : false
        end
      end

      def attribute(attribute_name)
        attributes[attribute_name] ||
          raise(ArgumentError, "Attribute with name #{attribute_name.inspect} is not defined on this Set")
      end

      def compound?
        false
      end

      def set
        self
      end

      def sets
        [self]
      end

      def insert(tuple)
        raise "Relation must be retained" unless retained?
        raise ArgumentError, "Passed in Tuple's relation must be #{self}" unless tuple.relation == self
        unless find(tuple[:id]).nil?
          raise ArgumentError, "Tuple with id #{tuple[:id]} already exists in this Set"
        end
        tuples.push(tuple)
        insert_subscription_node.call(tuple)
        tuple.on_update do |attribute, old_value, new_value|
          tuple_update_subscription_node.call tuple, attribute, old_value, new_value
        end
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
          insert(tuple) if find(tuple[:id]).nil?
        end
      end

      def to_sql
        to_arel.to_sql
      end

      def to_arel
        @arel ||= Arel::Table.new(name, Adapters::Arel::Engine.new(self))
      end

      protected
      attr_reader :signals

      def initial_read
        []
      end
    end
  end
end