module Unison
  module Relations
    class InnerJoin
      attr_reader :operand_1, :operand_2, :predicate
      def initialize(operand_1, operand_2, predicate)
        @operand_1, @operand_2, @predicate = operand_1, operand_2, predicate
      end
    end
  end
end