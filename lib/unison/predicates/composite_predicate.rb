module Unison
  module Predicates
    class CompositePredicate < Base
      attr_reader :operands
      retain :operands

      subscribe do
        operands.map do |operand|
          operand.on_update do
            update_subscription_node.call
          end
        end
      end
      
      def initialize(*operands)
        raise ArgumentError, "And predicate must have at least one child Predicate" if operands.empty?
        super()
        @operands = operands
      end

      def ==(other)
        if other.is_a?(self.class)
          operands == other.operands
        else
          false
        end
      end
    end
  end
end