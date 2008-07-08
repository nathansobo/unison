module Unison
  module Predicates
    class Eq
      attr_reader :operand_1, :operand_2
      def initialize(operand_1, operand_2)
        @operand_1, @operand_2 = operand_1, operand_2
      end

      def ==(other)
        return false unless other.instance_of?(Eq)
        operand_1 == other.operand_1 && operand_2 == other.operand_2 
      end

      def call(tuple)
        tuple.bind(operand_1) == tuple.bind(operand_2)
      end
    end
  end
end