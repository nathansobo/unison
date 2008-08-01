module Unison
  module Predicates
    class Or < CompositePredicate
      def eval(tuple)
        child_predicates.any? do |child_predicate|
          child_predicate.eval(tuple)
        end
      end
    end
  end
end