module Unison
  module Relations
    class Projection < Relation
      attr_reader :operand, :projected_set
      retains :operand

      def initialize(operand, projected_set)
        super()
        @operand, @projected_set = operand, projected_set
        @operand_subscriptions = []
        @last_update = nil
      end

      def to_sql
        to_arel.to_sql
      end

      def to_arel
        Arel::Project.new( operand.to_arel, *projected_set.to_arel.attributes )
      end

      def tuple_class
        projected_set.tuple_class
      end

      def merge(tuples)
        projected_set.merge(tuples)
      end

      def push(repository)
        operand.push(repository)
      end
      
      def set
        projected_set
      end

      def composed_sets
        operand.composed_sets
      end

      protected
      attr_reader :last_update, :operand_subscriptions

      def initial_read
        operand.tuples.map do |tuple|
          tuple[projected_set]
        end.uniq
      end

      def after_first_retain
        super
        operand_subscriptions.push(
          operand.on_insert do |created|
            restricted = created[projected_set]
            unless tuples.include?(restricted)
              tuples.push(restricted)
              insert_subscription_node.call(restricted)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_delete do |deleted|
            restricted = deleted[projected_set]
            unless initial_read.include?(restricted)
              tuples.delete(restricted)
              delete_subscription_node.call(restricted)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_tuple_update do |updated, attribute, old_value, new_value|
            restricted = updated[projected_set]
            # TODO: BT/NS - Make sure that this condition is sufficient for nested composite Tuples
            if projected_set.has_attribute?(attribute) && last_update != [restricted, attribute, old_value, new_value]
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
