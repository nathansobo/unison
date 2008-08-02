module Unison
  module Relations
    class InnerJoin < Relation
      attr_reader :operand_1, :operand_2, :predicate
      retains :operand_1, :operand_2, :predicate
      
      def initialize(operand_1, operand_2, predicate)
        super()
        @operand_1, @operand_2, @predicate = operand_1, operand_2, predicate
        @operand_1_subscriptions, @operand_2_subscriptions = [], []
        @tuples = initial_read

        operand_1_subscriptions.push(
          operand_1.on_insert do |operand_1_tuple|
            operand_2.each do |operand_2_tuple|
              insert_if_predicate_matches CompoundTuple::Base.new(operand_1_tuple, operand_2_tuple)
            end
          end
        )

        operand_2_subscriptions.push(
          operand_2.on_insert do |operand_2_tuple|
            operand_1.each do |operand_1_tuple|
              insert_if_predicate_matches CompoundTuple::Base.new(operand_1_tuple, operand_2_tuple)
            end
          end
        )

        operand_1_subscriptions.push(
          operand_1.on_delete do |operand_1_tuple|
            delete_if_member_of_compound_tuple operand_1, operand_1_tuple
          end
        )

        operand_2_subscriptions.push(
          operand_2.on_delete do |operand_2_tuple|
            delete_if_member_of_compound_tuple operand_2, operand_2_tuple
          end
        )

        operand_1_subscriptions.push(
          operand_1.on_tuple_update do |operand_1_tuple, attribute, old_value, new_value|
            operand_2.each do |operand_2_tuple|
              compound_tuple = CompoundTuple::Base.new(operand_1_tuple, operand_2_tuple)
              if tuples.include?(compound_tuple)
                if predicate.eval(compound_tuple)
                  tuple_update_subscription_node.call compound_tuple, attribute, old_value, new_value
                else
                  delete_compound_tuple compound_tuple
                end
              else
                insert_if_predicate_matches compound_tuple
              end
            end
          end
        )

        operand_2_subscriptions.push(
          operand_2.on_tuple_update do |operand_2_tuple, attribute, old_value, new_value|
            operand_1.each do |operand_1_tuple|
              compound_tuple = CompoundTuple::Base.new(operand_1_tuple, operand_2_tuple)
              if tuples.include?(compound_tuple)
                if predicate.eval(compound_tuple)
                  tuple_update_subscription_node.call compound_tuple, attribute, old_value, new_value
                else
                  delete_compound_tuple compound_tuple
                end
              else
                insert_if_predicate_matches compound_tuple
              end
            end
          end
        )
      end

      protected
      attr_reader :tuples, :operand_1_subscriptions, :operand_2_subscriptions

      def destroy
        operand_1_subscriptions.each do |subscription|
          subscription.destroy
        end
        operand_2_subscriptions.each do |subscription|
          subscription.destroy
        end
        operand_1.release(self)
        operand_2.release(self)
        predicate.release(self)
      end

      def insert_if_predicate_matches(compound_tuple)
        if predicate.eval(compound_tuple)
          tuples.push(compound_tuple)
          insert_subscription_node.call(compound_tuple)
        end
      end

      def delete_if_member_of_compound_tuple(operand, tuple)
        tuples.each do |compound_tuple|
          if compound_tuple[operand] == tuple
            delete_compound_tuple compound_tuple
          end
        end
      end

      def delete_compound_tuple(compound_tuple)
        tuples.delete(compound_tuple)
        delete_subscription_node.call(compound_tuple)
      end

      def initial_read
        cartesian_product.select {|tuple| predicate.eval(tuple)}
      end

      def cartesian_product
        tuples = []
        operand_1.each do |tuple_1|
          operand_2.each do |tuple_2|
            tuples.push(CompoundTuple::Base.new(tuple_1, tuple_2))
          end
        end
        tuples
      end
    end
  end
end
