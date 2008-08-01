module Unison
  module Predicates
    class And < CompositePredicate
      def eval(tuple)
        child_predicates.all? do |child_predicate|
          child_predicate.eval(tuple)
        end
      end
    end
  end
end