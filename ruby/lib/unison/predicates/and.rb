module Unison
  module Predicates
    class And < CompositePredicate
      def eval(tuple)
        operands.all? do |operand|
          operand.eval(tuple)
        end
      end

      def to_arel
        operands.inject(nil) do |acc, operand|
          acc ? acc.and(operand.to_arel) : operand.to_arel
        end
      end
    end
  end
end