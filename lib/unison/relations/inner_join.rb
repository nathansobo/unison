module Unison
  module Relations
    class InnerJoin < Relation
      attr_reader :operand_1, :operand_2, :predicate
      def initialize(operand_1, operand_2, predicate)
        super()
        @operand_1, @operand_2, @predicate = operand_1, operand_2, predicate
        @tuples = initial_read

        operand_2.on_insert do |operand_2_tuple|
          operand_1.each do |operand_1_tuple|
            compound_tuple = tuple_class.new(operand_1_tuple, operand_2_tuple)
            if predicate.eval(compound_tuple)
              tuples.push(compound_tuple)
              trigger_on_insert(compound_tuple)
            end
          end
        end

        operand_1.on_insert do |operand_1_tuple|
          operand_2.each do |operand_2_tuple|
            compound_tuple = tuple_class.new(operand_1_tuple, operand_2_tuple)
            if predicate.eval(compound_tuple)
              tuples.push(compound_tuple)
              trigger_on_insert(compound_tuple)
            end
          end
        end

        operand_1.on_delete do |operand_1_tuple|
          tuples.each do |compound_tuple|
            if compound_tuple[operand_1] == operand_1_tuple
              tuples.delete(compound_tuple)
              trigger_on_delete(compound_tuple)
            end
          end
        end

        operand_2.on_delete do |operand_2_tuple|
          tuples.each do |compound_tuple|
            if compound_tuple[operand_2] == operand_2_tuple
              tuples.delete(compound_tuple)
              trigger_on_delete(compound_tuple)
            end
          end
        end
      end

      def read
        @tuples
      end

      protected
      attr_reader :tuples

      def initial_read
        cartesian_product.select {|tuple| predicate.eval(tuple)}
      end

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
