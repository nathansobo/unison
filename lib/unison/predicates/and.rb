module Unison
  module Predicates
    class And < CompositePredicate
      def eval(tuple)
        operands.all? do |operand|
          operand.eval(tuple)
        end
      end

      def to_sql
        "(#{operands.map {|operand| operand.to_sql}.join(" and ")})"
      end
    end
  end
end