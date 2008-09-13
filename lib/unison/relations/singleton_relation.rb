module Unison
  module Relations
    class SingletonRelation < CompositeRelation
      attr_reader :operand
      retain :operand

      subscribe do
        operand.on_insert do |inserted|
          if inserted == operand.tuples.first
            old_tuple = delete_without_callback(tuple)
            insert_without_callback(inserted)
            delete_subscription_node.call(old_tuple)
            insert_subscription_node.call(tuple)
          end
        end
      end

      subscribe do
        operand.on_delete do |deleted|
        end
      end

      subscribe do
        operand.on_tuple_update do |tuple, attribute, old_value, new_value|
        end
      end

      def initialize(operand)
        super()
        @operand = operand
      end

      def merge(tuples)
        raise "Relation must be retained" unless retained?
        operand.merge(tuples)
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

      protected
      def initial_read
        [operand.tuples.first]
      end

      def delegate_to_read(method_name, *args, &block)
        tuples.first.send(method_name, *args, &block)
      end
    end
  end
end