module Unison
  module Relations
    class AttributesProjection < CompositeRelation
      attr_reader :operand, :projected_attributes

      retain :operand

      subscribe do
        operand.on_insert do |inserted_tuple|
          insert(projected_tuple_for(inserted_tuple))
        end
      end

      def initialize(operand, projected_attributes)
        super()
        @operand = operand
        @projected_attributes = translate_symbols_to_attributes(projected_attributes)
      end

      def attribute(name)
        raise ArgumentError, "Attribute with name #{name.inspect} is not defined on this Relation" unless has_attribute?(name)
        projected_attributes.detect do |attribute|
          attribute.name == name
        end
      end
      
      def has_attribute?(name)
        projected_attributes.any? do |attribute|
          attribute.name == name
        end
      end

      protected
      def initial_read
        projected_tuples = []
        operand.tuples.map do |tuple|
          fields = projected_attributes.map do |attribute|
            tuple.field_for(attribute)
          end
          new_projected_tuple = ProjectedTuple.new(*fields)
        end
      end

      def translate_symbols_to_attributes(attributes_or_symbols)
        attributes_or_symbols.map do |attribute_or_symbol|
          if attribute_or_symbol.is_a?(Attributes::Attribute)
            attribute_or_symbol
          else
            operand.attribute(attribute_or_symbol)
          end
        end
      end

      def projected_tuple_for(tuple)
        fields = projected_attributes.map {|attribute| tuple.field_for(attribute) }
        ProjectedTuple.new(*fields)
      end
    end
  end
end
