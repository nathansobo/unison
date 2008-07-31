module Unison
  module Relations
    class Set < Relation
      attr_reader :name, :attributes, :tuples

      def initialize(name)
        super()
        @name = name
        @attributes = []
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
        attribute = Attribute.new(self, name, type)
        attributes.push(attribute)
        attribute
      end

      def has_attribute?(attribute_or_symbol)
        case attribute_or_symbol
        when Attribute
          attributes.include?(attribute_or_symbol)
        when Symbol
          attributes.any? {|attribute| attribute.name == attribute_or_symbol}
        end
      end

      def [](attribute_name)
        attributes.detect {|attribute| attribute.name == attribute_name} ||
          raise(ArgumentError, "Attribute with name #{attribute_name.inspect} is not defined on this Set")
      end

      def insert(tuple)
        tuples.push(tuple)
        tuple.on_update do |attribute, old_value, new_value|
          trigger_on_tuple_update tuple, attribute, old_value, new_value
        end
        trigger_on_insert(tuple)
      end

      def delete(tuple)
        raise ArgumentError, "Tuple: #{tuple.inspect}\nis not in the set" unless tuples.include?(tuple)
        tuples.delete(tuple)
        delete_subscriptions.each do |proc|
          proc.call(tuple)
        end
        tuple
      end

      def each(&block)
        tuples.each(&block)
      end

      protected
      attr_reader :signals
    end
  end
end