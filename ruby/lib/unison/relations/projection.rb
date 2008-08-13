module Unison
  module Relations
    class Projection < Relation
      attr_reader :operand, :attributes
      retains :operand

      def initialize(operand, attributes)
        super()
        @operand, @attributes = operand, attributes
        @operand_subscriptions = []
        @last_update = nil
      end

      def to_sql
        to_arel.to_sql
      end

      def to_arel
        Arel::Project.new( operand.to_arel, *attributes.to_arel.attributes )
      end

      def tuple_class
        attributes.tuple_class
      end

      def merge(tuples)
        attributes.merge(tuples)
      end

      def push(repository)
        repository.push(self)
      end
      
      def set
        attributes
      end

      def sets
        operand.sets
      end

      protected
      attr_reader :last_update, :operand_subscriptions

      def initial_read
        operand.tuples.map do |tuple|
          tuple[attributes]
        end.uniq
      end

      def after_first_retain
        super
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

      def after_last_release
        operand_subscriptions.each do |subscription|
          subscription.destroy
        end
        operand.release(self)
      end
    end
  end
end
