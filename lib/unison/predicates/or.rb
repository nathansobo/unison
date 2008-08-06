module Unison
  module Predicates
    class Or < CompositePredicate
      def eval(tuple)
        operands.any? do |operand|
          operand.eval(tuple)
        end
      end
    end
  end
end