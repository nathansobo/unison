module Unison
  module Attributes
    class Attribute
      module PredicateConstructors
        def eq(other)
          Predicates::EqualTo.new(self, other)
        end

        def neq(other)
          Predicates::NotEqualTo.new(self, other)
        end

        def gt(other)
          Predicates::GreaterThan.new(self, other)
        end

        def lt(other)
          Predicates::LessThan.new(self, other)
        end

        def gteq(other)
          Predicates::GreaterThanOrEqualTo.new(self, other)
        end

        def lteq(other)
          Predicates::LessThanOrEqualTo.new(self, other)
        end
      end
      include PredicateConstructors
      
      attr_reader :set, :name

      def initialize(set, name)
        @set, @name = set, name
      end
    end
  end
end