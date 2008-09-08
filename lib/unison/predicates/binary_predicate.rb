module Unison
  module Predicates
    class BinaryPredicate < Base
      attr_reader :operand_1, :operand_2

      retain :subscribable_operands
      subscribe do
        subscribable_operands.map do |operand|
          operand.on_update do
            update_subscription_node.call
          end
        end
      end

      def initialize(operand_1, operand_2)
        super()
        @operand_1, @operand_2 = operand_1, operand_2
      end

      def ==(other)
        if other.instance_of?(self.class)
          operand_1 == other.operand_1 && operand_2 == other.operand_2
        else
          false
        end
      end

      def eval(tuple)
        apply(tuple.bind(eval_operand(operand_1)), tuple.bind(eval_operand(operand_2)))
      end

      def to_arel
        raise NotImplementedError
      end

      protected

      def apply(value_1, value_2)
        raise NotImplementedError
      end

      def subscribable_operands
        operands.find_all do |operand|
          operand.is_a?(Signal)
        end
      end

      def operands
        [operand_1, operand_2]
      end

      def eval_operand(operand)
        operand.is_a?(Signal) ? operand.value : operand
      end
    end
  end
end