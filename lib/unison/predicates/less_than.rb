module Unison
  module Predicates
    class LessThan < BinaryPredicate
      def to_arel
        Arel::LessThan.new(operand_1.to_arel, operand_2.to_arel)
      end

      def inspect
        "#{operand_1.inspect}.lt(#{operand_2.inspect})"
      end

      protected

      def apply(value_1, value_2)
        value_1 < value_2
      end
    end
  end
end