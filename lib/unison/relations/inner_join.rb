module Unison
  module Relations
    class InnerJoin < Relation
      attr_reader :operand_1, :operand_2, :predicate
      def initialize(operand_1, operand_2, predicate)
        super()
        @operand_1, @operand_2, @predicate = operand_1, operand_2, predicate
      end

      def read
        cartesian_product.select {|tuple| predicate.eval(tuple)}
      end

      protected
      def cartesian_product
        tuples = []
        operand_1.each do |tuple_1|
          operand_2.each do |tuple_2|
            tuples.push(tuple_class.new(tuple_1, tuple_2))
          end
        end
        tuples
      end
    end
  end
end