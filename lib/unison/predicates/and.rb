module Unison
  module Predicates
    class And < Base
      attr_reader :child_predicates
      def initialize(*child_predicates)
        raise ArgumentError, "And predicate must have at least one child Predicate" if child_predicates.empty?
        @child_predicates = child_predicates
      end

      def eval(tuple)
        child_predicates.all? do |child_predicate|
          child_predicate.eval(tuple)
        end
      end

      def ==(other)
        if other.is_a?(And)
          child_predicates == other.child_predicates
        else
          false
        end
      end
    end
  end
end