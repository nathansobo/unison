module Unison
  module Predicates
    class EqualTo < BinaryPredicate
      def fetch_arel
        Arel::Equality.new(operand_1.fetch_arel, operand_2.fetch_arel)
      end

      def inspect
        "#{operand_1.inspect}.eq(#{operand_2.inspect})"
      end

      protected
      def apply(value_1, value_2)
        value_1 == value_2
      end
    end
  end
end