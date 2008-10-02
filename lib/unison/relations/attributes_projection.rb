module Unison
  module Relations
    class AttributesProjection < CompositeRelation
      attr_reader :operand, :projected_attributes
      
      def initialize(operand, projected_attributes)
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
      def translate_symbols_to_attributes(attributes_or_symbols)
        attributes_or_symbols.map do |attribute_or_symbol|
          if attribute_or_symbol.is_a?(Attributes::Attribute)
            attribute_or_symbol
          else
            operand.attribute(attribute_or_symbol)
          end
        end
      end
    end
  end
end
