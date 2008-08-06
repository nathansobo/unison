module Unison
  module Predicates
    class And < CompositePredicate
      def eval(tuple)
        operands.all? do |operand|
          operand.eval(tuple)
        end
      end
    end
  end
end