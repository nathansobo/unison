module Unison
  module Predicates
    class Lteq < BinaryPredicate
      def to_arel
        Arel::LessThanOrEqualTo.new(operand_1.to_arel, operand_2.to_arel)
      end

      protected

      def apply(value_1, value_2)
        value_1 <= value_2
      end
    end
  end
end