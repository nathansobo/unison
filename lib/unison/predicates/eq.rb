module Unison
  module Predicates
    class Eq < Base
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
        if other.instance_of?(Eq)
          operand_1 == other.operand_1 && operand_2 == other.operand_2
        else
          false
        end
      end

      def eval(tuple)
        tuple.bind(eval_operand(operand_1)) == tuple.bind(eval_operand(operand_2))
      end

      def to_arel
        Arel::Equality.new(operand_1.to_arel, operand_2.to_arel)
      end

      protected

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