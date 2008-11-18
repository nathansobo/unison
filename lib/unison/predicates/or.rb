module Unison
  module Predicates
    class Or < CompositePredicate
      def eval(tuple)
        operands.any? do |operand|
          operand.eval(tuple)
        end
      end

      def fetch_arel
        operands.inject(nil) do |acc, operand|
          acc ? acc.or(operand.fetch_arel) : operand.fetch_arel
        end
      end

      def inspect
        "or(#{operands.map {|operand| operand.inspect}.join(", ")})"
      end
    end
  end
end