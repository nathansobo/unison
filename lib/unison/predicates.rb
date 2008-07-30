module Unison
  module Predicates
    class Eq
      attr_reader :operand_1, :operand_2
      def initialize(operand_1, operand_2)
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

      protected
      def eval_operand(operand)
        operand.is_a?(Signal) ? operand.value : operand
      end
    end
  end
end