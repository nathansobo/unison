module Unison
  module Relations
    class Selection < Relation
      attr_reader :operand, :predicate, :operand_subscriptions, :predicate_subscription

      def initialize(operand, predicate)
        super()
        @operand_subscriptions = []
        @operand, @predicate = operand, predicate
        @tuples = initial_read

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
              tuples.push(created)
              insert_subscription_node.call(created)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_delete do |deleted|
            if predicate.eval(deleted)
              tuples.delete(deleted)
              delete_subscription_node.call(deleted)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_tuple_update do |tuple, attribute, old_value, new_value|
            if predicate.eval(tuple)
              if tuples.include?(tuple)
                tuple_update_subscription_node.call(tuple, attribute, old_value, new_value)
              else
                tuples.push(tuple)
                insert_subscription_node.call(tuple)
              end
            else
              tuples.delete(tuple)
              delete_subscription_node.call(tuple)
            end
          end
        )
      end

      def size
        read.size
      end

      def retain(object)
        super
        predicate.retain(self)
        operand.retain(self)
      end

      protected
      attr_reader :tuples

      def initial_read
        operand.read.select do |tuple|
          predicate.eval(tuple)
        end
      end

      def destroy
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