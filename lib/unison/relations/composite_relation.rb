module Unison
  module Relations
    class CompositeRelation < Relation
      def attribute(name)
        operands.each do |operand|
          return operand.attribute(name) if operand.has_attribute?(name)
        end
        raise ArgumentError, "Attribute with name #{name.inspect} is not defined on this Relation"
      end

      def has_attribute?(attribute)
        operands.any? do |operand|
          operand.has_attribute?(attribute)
        end
      end  

      def operands
        [operand]
      end
    end
  end
end