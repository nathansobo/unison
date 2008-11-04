module Unison
  module Relations
    class SetProjection < CompositeRelation
      attr_reader :operand, :projected_set
      retain :operand

      subscribe do
        operand.on_insert do |created|
          restricted = created[projected_set]
          unless tuples.include?(restricted)
            tuples.push(restricted)
            insert_subscription_node.call(restricted)
          end
        end
      end

      subscribe do
        operand.on_delete do |deleted|
          restricted = deleted[projected_set]
          unless initial_read.include?(restricted)
            tuples.delete(restricted)
            delete_subscription_node.call(restricted)
          end
        end
      end

      subscribe do
        operand.on_tuple_update do |updated, attribute, old_value, new_value|
          restricted = updated[projected_set]
          # TODO: BT/NS - Make sure that this condition is sufficient for nested composite Tuples
          if projected_set.has_attribute?(attribute) && last_update != [restricted, attribute, old_value, new_value]
            @last_update = [restricted, attribute, old_value, new_value]
            tuple_update_subscription_node.call(restricted, attribute, old_value, new_value)
          end
        end
      end

      def initialize(operand, projected_set)
        super()
        @operand, @projected_set = operand, projected_set
        @last_update = nil
      end

      def attribute(name)
        projected_set.attribute(name)
      end

      def has_attribute?(attribute)
        projected_set.has_attribute?(attribute)
      end 

      def to_arel
        Arel::Project.new( operand.to_arel, *projected_set.to_arel.attributes )
      end

      def tuple_class
        projected_set.tuple_class
      end

      def new_tuple(attributes)
        projected_set.new_tuple(attributes)
      end

      def merge(tuples)
        projected_set.merge(tuples)
      end

      def push
        operand.push
      end
      
      def set
        projected_set
      end

      def composed_sets
        operand.composed_sets
      end

      def inspect
        "#{operand.inspect}.project(#{projected_set.inspect})"
      end

      protected
      attr_reader :last_update

      def initial_read
        operand.tuples.map do |tuple|
          tuple[projected_set]
        end.uniq
      end
    end
  end
end
