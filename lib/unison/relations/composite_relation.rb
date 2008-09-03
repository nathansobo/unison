module Unison
  module Relations
    class CompositeRelation < Relation
      def initialize
        super
        @operand_subscriptions = []
      end

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

      protected
      attr_reader :operand_subscriptions

      def after_last_release
        operand_subscriptions.each do |subscription|
          subscription.destroy
        end
        operands.each do |operand|
          operand.release(self)
        end
      end      
    end
  end
end