module Unison
  module Relations
    class SingletonRelation < CompositeRelation
      attr_reader :operand
      retain :operand

      subscribe do
        operand.on_insert do |inserted|
          if inserted == operand.tuples.first
            swap_tuple(inserted)
          end
        end
      end

      subscribe do
        operand.on_delete do |deleted|
          if deleted == tuple
            swap_tuple(operand.tuples.first)
          end
        end
      end

      subscribe do
        operand.on_tuple_update do |updated_tuple, attribute, old_value, new_value|
          if updated_tuple == tuple
            if updated_tuple == operand.tuples.first
              tuple_updated(attribute, old_value, new_value)
            else
              swap_tuple(operand.tuples.first)
            end
          else
            if updated_tuple == operand.tuples.first
              swap_tuple(updated_tuple)
            end
          end
        end
      end

      def initialize(operand)
        super()
        @change_subscription_node = SubscriptionNode.new(self)
        @operand = operand
      end

      def merge(tuples)
        operand.merge(tuples)
      end

      def fetch
        super.first
      end

      def singleton
        self
      end

      def tuple
        tuples.first
      end

      def nil?
        tuple.nil?
      end

      def tuple_class
        operand.tuple_class
      end

      def to_arel
        operand.to_arel.take(1)
      end

      def set
        operand.set
      end

      def composed_sets
        operand.composed_sets
      end

      def inspect
        "<#{self.class}:#{object_id} @operand=#{operand.inspect}>"
      end

      def on_change(*args, &block)
        change_subscription_node.subscribe(*args, &block)
      end      

      protected
      attr_reader :change_subscription_node

      def tuple_updated(attribute, old_value, new_value)
        tuple_update_subscription_node.call(tuple, attribute, old_value, new_value)
        change_subscription_node.call(self)
      end

      def swap_tuple(new_tuple)
        old_tuple = tuple
        delete_without_callback(old_tuple) unless old_tuple.nil?
        insert_without_callback(new_tuple) unless new_tuple.nil?
        delete_subscription_node.call(old_tuple) unless old_tuple.nil?
        insert_subscription_node.call(new_tuple) unless new_tuple.nil?
        change_subscription_node.call(self)
      end      

      def initial_read
        [operand.tuples.first].compact
      end

      def delegate_to_read(method_name, *args, &block)
        tuples.first.send(method_name, *args, &block)
      end
    end
  end
end