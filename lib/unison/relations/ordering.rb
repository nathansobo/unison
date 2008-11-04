module Unison
  module Relations
    class Ordering < CompositeRelation
      attr_reader :operand, :order_by_attributes
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

      def initialize(operand, *order_by_attributes)
        super()
        @operand = operand 
        @order_by_attributes = attributes_for(order_by_attributes)
      end

      def pull
        operand.pull
        self
      end

      def merge(tuples)
        operand.merge(tuples)
      end

      def to_arel
        operand.to_arel.order(*order_by_attributes.map {|order_by_attribute| order_by_attribute.to_arel})
      end

      def tuple_class
        operand.tuple_class
      end

      def new_tuple(attributes)
        operand.new_tuple(attributes)
      end

      def set
        operand.set
      end

      def composed_sets
        operand.composed_sets
      end

      def inspect
        "#{operand.inspect}.order_by(#{order_by_attributes.map {|attribute| attribute.inspect}.join(", ")})"
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

      #TODO: Introduce directionality on order_by_attributes
      def direction_coefficient(attribute)
        1
      end

      def comparator
        lambda do |a, b|
          compare(a, b)
        end
      end

      def compare(a, b)
        order_by_attributes.each do |attribute|
          result = direction_coefficient(attribute) * (a[attribute] <=> b[attribute])
          return result unless result == 0
        end
        0
      end

      def attributes_for(attributes_or_symbols)
        attributes_or_symbols.map do |attribute_or_symbol|
          case attribute_or_symbol
          when Symbol
            operand.attribute(attribute_or_symbol)
          when Attributes::Attribute
            attribute_or_symbol
          end
        end
      end
    end
  end
end
