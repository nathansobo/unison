module Unison
  module Relations
    class InnerJoin < CompositeRelation
      attr_reader :operand_1, :operand_2, :predicate
      retain :operand_1, :operand_2

      subscribe do
        operand_1.on_insert do |operand_1_tuple|
          operand_2.each do |operand_2_tuple|
            insert_if_predicate_matches CompositeTuple.new(operand_1_tuple, operand_2_tuple)
          end
        end
      end

      subscribe do
        operand_2.on_insert do |operand_2_tuple|
          operand_1.each do |operand_1_tuple|
            insert_if_predicate_matches CompositeTuple.new(operand_1_tuple, operand_2_tuple)
          end
        end
      end

      subscribe do
        operand_1.on_delete do |operand_1_tuple|
          delete_if_member_of_compound_tuple :left, operand_1_tuple
        end
      end

      subscribe do
        operand_2.on_delete do |operand_2_tuple|
          delete_if_member_of_compound_tuple :right, operand_2_tuple
        end
      end

      subscribe do
        operand_1.on_tuple_update do |operand_1_tuple, attribute, old_value, new_value|
          operand_2.tuples.each do |operand_2_tuple|
            compound_tuple = find_compound_tuple(operand_1_tuple, operand_2_tuple)
            if compound_tuple
              if predicate.eval(compound_tuple)
                tuple_update_subscription_node.call(compound_tuple, attribute, old_value, new_value)
              else
                delete(compound_tuple)
              end
            else
              insert_if_predicate_matches(CompositeTuple.new(operand_1_tuple, operand_2_tuple))
            end
          end
        end
      end

      subscribe do
        operand_2.on_tuple_update do |operand_2_tuple, attribute, old_value, new_value|
          operand_1.tuples.each do |operand_1_tuple|
            compound_tuple = find_compound_tuple(operand_1_tuple, operand_2_tuple)
            if compound_tuple
              if predicate.eval(compound_tuple)
                tuple_update_subscription_node.call(compound_tuple, attribute, old_value, new_value)
              else
                delete(compound_tuple)
              end
            else
              insert_if_predicate_matches(CompositeTuple.new(operand_1_tuple, operand_2_tuple))
            end
          end
        end
      end

      def initialize(operand_1, operand_2, predicate)
        super()
        @operand_1, @operand_2, @predicate = operand_1, operand_2, predicate
      end

      def operands
        [operand_1, operand_2]
      end

      def to_arel
        operand_1.to_arel.join(operand_2.to_arel).on(predicate.to_arel)
      end

      def compound?
        true
      end

      def set
        raise NotImplementedError
      end

      def composed_sets
        operand_1.composed_sets + operand_2.composed_sets
      end

      def merge(tuples)
        raise NotImplementedError
      end

      def inspect
        "<#{self.class}:#{object_id} @operand_1=#{operand_1.inspect} @operand_2=#{operand_2.inspect} @predicate=#{predicate.inspect}>"
      end

      protected
      def insert_if_predicate_matches(compound_tuple)
        insert(compound_tuple) if predicate.eval(compound_tuple)
      end

      def delete_if_member_of_compound_tuple(which_operand, tuple)
        tuples.each do |compound_tuple|
          if compound_tuple.send(which_operand) == tuple
            delete(compound_tuple)
          end
        end
      end

      def initial_read
        cartesian_product.select {|tuple| predicate.eval(tuple)}
      end

      def cartesian_product
        tuples = []
        operand_1.tuples.each do |tuple_1|
          operand_2.tuples.each do |tuple_2|
            tuples.push(CompositeTuple.new(tuple_1, tuple_2))
          end
        end
        tuples
      end

      def find_compound_tuple(operand_1_tuple, operand_2_tuple)
        tuples.find do |compound_tuple|
          compound_tuple.left == operand_1_tuple && compound_tuple.right == operand_2_tuple
        end
      end
    end
  end
end
