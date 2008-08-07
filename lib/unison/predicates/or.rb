module Unison
  module Predicates
    class Or < CompositePredicate
      def eval(tuple)
        operands.any? do |operand|
          operand.eval(tuple)
        end
      end

      def to_sql
        "(#{operands.map {|operand| operand.to_sql}.join(" or ")})"
      end
    end
  end
end