module Unison
  module Predicates
    class Or < Base
      attr_reader :child_predicates
      def initialize(*child_predicates)
        raise ArgumentError, "And predicate must have at least one child Predicate" if child_predicates.empty?
        super()
        @child_predicates = child_predicates
      end

      def eval(tuple)
        child_predicates.any? do |child_predicate|
          child_predicate.eval(tuple)
        end
      end

      def ==(other)
        if other.is_a?(Or)
          child_predicates == other.child_predicates
        else
          false
        end
      end
    end
  end
end