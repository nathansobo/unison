module Unison
  module Relations
    class Projection < Relation
      attr_reader :operand, :attributes
      retains :operand

      def initialize(operand, attributes)
        super()
        @operand, @attributes = operand, attributes
        @operand_subscriptions = []
        @tuples = initial_read
        @last_update = nil
      end

      protected
      attr_reader :tuples, :last_update, :operand_subscriptions

      def initial_read
        operand.read.map do |tuple|
          tuple[attributes]
        end.uniq
      end

      def after_first_retain
        operand_subscriptions.push(
          operand.on_insert do |created|
            restricted = created[attributes]
            unless tuples.include?(restricted)
              tuples.push(restricted)
              insert_subscription_node.call(restricted)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_delete do |deleted|
            restricted = deleted[attributes]
            unless initial_read.include?(restricted)
              tuples.delete(restricted)
              delete_subscription_node.call(restricted)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_tuple_update do |updated, attribute, old_value, new_value|
            restricted = updated[attributes]
            # TODO: BT/NS - Make sure that this condition is sufficient for nested composite Tuples
            if attributes.has_attribute?(attribute) && last_update != [restricted, attribute, old_value, new_value]
              @last_update = [restricted, attribute, old_value, new_value]
              tuple_update_subscription_node.call(restricted, attribute, old_value, new_value)
            end
          end
        )
      end

      def destroy
        operand_subscriptions.each do |subscription|
          subscription.destroy
        end
        operand.release(self)
      end
    end
  end
end
