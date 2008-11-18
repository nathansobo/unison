module Unison
  module Predicates
    class LessThanOrEqualTo < BinaryPredicate
      def fetch_arel
        Arel::LessThanOrEqualTo.new(operand_1.fetch_arel, operand_2.fetch_arel)
      end

      def inspect
        "#{operand_1.inspect}.lteq(#{operand_2.inspect})"
      end

      protected

      def apply(value_1, value_2)
        value_1 <= value_2
      end
    end
  end
end