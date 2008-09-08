module Unison
  module Relations
    class Ordering < CompositeRelation
      attr_reader :operand, :order_by_attribute
      retain :operand

      subscribe do
        operand.on_insert do |inserted|
          insert(inserted)
        end
      end
      subscribe do
        operand.on_delete do |inserted|
          delete(inserted)
        end
      end
      subscribe do
        operand.on_tuple_update do |tuple, attribute, old_value, new_value|
          reorder_tuples
          tuple_update_subscription_node.call(tuple, attribute, old_value, new_value)
        end
      end

      def initialize(operand, order_by_attribute)
        super()
        @operand, @order_by_attribute = operand, order_by_attribute
      end

      def merge(tuples)
        raise "Relation must be retained" unless retained?
        operand.merge(tuples)
      end

      def to_arel
        operand.to_arel.order(order_by_attribute.to_arel)
      end

      def tuple_class
        operand.tuple_class
      end

      def set
        operand.set
      end

      def composed_sets
        operand.composed_sets
      end

      def inspect
        "<#{self.class}:#{object_id} @operand=#{operand.inspect} @order_by_attribute=#{order_by_attribute.inspect}>"
      end

      protected

      def add_to_tuples(tuple_to_add)
        super
        reorder_tuples
      end

      def reorder_tuples
        tuples.sort!(&comparator)
      end

      def initial_read
        operand.tuples.sort(&comparator)
      end
      
      def comparator
        direction_coefficient = order_by_attribute.ascending?? 1 : -1
        lambda do |a, b|
          (a[order_by_attribute] <=> b[order_by_attribute]) * direction_coefficient
        end
      end
    end
  end
end
