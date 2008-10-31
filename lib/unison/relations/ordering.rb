module Unison
  module Relations
    class Ordering < CompositeRelation
      attr_reader :operand, :ordering_attributes
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

      def initialize(operand, *ordering_attributes)
        super()
        @operand, @ordering_attributes = operand, ordering_attributes
      end

      def merge(tuples)
        operand.merge(tuples)
      end

      def to_arel
        operand.to_arel.order(*ordering_attributes.map {|ordering_attribute| ordering_attribute.to_arel})
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
        "#{operand.inspect}.order_by(#{ordering_attributes.map {|attribute| attribute.inspect}.join(", ")})"
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
      
      def direction_coefficient(attribute)
        attribute.ascending?? 1 : -1
      end

      def comparator
        lambda do |a, b|
          compare(a, b)
        end
      end

      def compare(a, b)
        ordering_attributes.each do |attribute|
          result = direction_coefficient(attribute) * (a[attribute] <=> b[attribute])
          return result unless result == 0
        end
        0
      end
    end
  end
end
