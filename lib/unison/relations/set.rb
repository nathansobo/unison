module Unison
  module Relations
    class Set < Relation
      attr_reader :name, :attributes, :tuples

      def initialize(name)
        super()
        @name = name
        @attributes = SequencedHash.new
        @tuples = []
      end

      def tuple_class
        @tuple_class ||= begin
          tuple_class = Class.new(Unison::PrimitiveTuple::Base)
          tuple_class.relation = self
          tuple_class
        end
      end
      attr_writer :tuple_class

      def attribute(name, type)
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

      def has_attribute?(attribute_or_symbol)
        case attribute_or_symbol
        when Attribute
          attributes.detect {|name, attribute| attribute == attribute_or_symbol}
        when Symbol
          attributes[attribute_or_symbol] ? true : false
        end
      end

      def [](attribute_name)
        attributes[attribute_name] ||
          raise(ArgumentError, "Attribute with name #{attribute_name.inspect} is not defined on this Set")
      end

      def insert(tuple)
        tuples.push(tuple)
        tuple.on_update do |attribute, old_value, new_value|
          tuple_update_subscription_node.call tuple, attribute, old_value, new_value
        end
        insert_subscription_node.call(tuple)
        tuple
      end

      def delete(tuple)
        raise ArgumentError, "Tuple: #{tuple.inspect}\nis not in the set" unless tuples.include?(tuple)
        tuples.delete(tuple)
        delete_subscription_node.call(tuple)
        tuple
      end

      def each(&block)
        tuples.each(&block)
      end

      def to_sql
        to_arel.to_sql
      end

      protected
      attr_reader :signals

      def to_arel
        Arel::Table.new(name, Adapters::Arel::Engine.new(self))
      end

      def initial_read
        tuples
      end
    end
  end
end