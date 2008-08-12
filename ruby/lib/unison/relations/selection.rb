module Unison
  module Relations
    class Selection < Relation
      attr_reader :operand, :predicate, :operand_subscriptions, :predicate_subscription
      retains :operand, :predicate

      def initialize(operand, predicate)
        super()
        @operand_subscriptions = []
        @operand, @predicate = operand, predicate
      end

      def to_sql
        to_arel.to_sql
      end

      def to_arel
        operand.to_arel.where(predicate.to_arel)
      end

      protected
      def initial_read
        operand.tuples.select do |tuple|
          predicate.eval(tuple)
        end
      end

      def after_first_retain
        super
        @predicate_subscription =
          predicate.on_update do
            new_tuples = initial_read
            deleted_tuples = tuples - new_tuples
            inserted_tuples = new_tuples - tuples
            tuples.clear
            tuples.concat initial_read
            deleted_tuples.each do |deleted_tuple|
              delete_subscription_node.call(deleted_tuple)
            end
            inserted_tuples.each do |inserted_tuple|
              insert_subscription_node.call(inserted_tuple)
            end
          end

        operand_subscriptions.push(
          operand.on_insert do |created|
            if predicate.eval(created)
              insert(created)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_delete do |deleted|
            if predicate.eval(deleted)
              delete(deleted)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_tuple_update do |tuple, attribute, old_value, new_value|
            if predicate.eval(tuple)
              if tuples.include?(tuple)
                tuple_update_subscription_node.call(tuple, attribute, old_value, new_value)
              else
                insert(tuple)
              end
            else
              delete(tuple)
            end
          end
        )
      end

      def after_last_release
        predicate_subscription.destroy
        operand_subscriptions.each do |subscription|
          subscription.destroy
        end
        predicate.release self
        operand.release self
      end
    end
  end
end