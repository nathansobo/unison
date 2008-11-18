module Unison
  module Predicates
    class And < CompositePredicate
      def eval(tuple)
        operands.all? do |operand|
          operand.eval(tuple)
        end
      end

      def fetch_arel
        operands.inject(nil) do |acc, operand|
          acc ? acc.and(operand.fetch_arel) : operand.fetch_arel
        end
      end

      def inspect
        "and(#{operands.map {|operand| operand.inspect}.join(", ")})"
      end
    end
  end
end