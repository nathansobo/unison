module Unison
  module Relations
    class Selection < CompositeRelation
      attr_reader :operand, :predicate
      retain :operand, :predicate

      subscribe do
        predicate.on_change do
          new_tuples = initial_read
          deleted_tuples = tuples - new_tuples
          inserted_tuples = new_tuples - tuples
          deleted_tuples.each{|tuple| delete(tuple)}
          inserted_tuples.each{|tuple| insert(tuple)}
        end
      end

      subscribe do
        operand.on_insert do |inserted|
          if predicate.eval(inserted)
            insert(inserted)
          end
        end
      end

      subscribe do
        operand.on_delete do |deleted|
          if predicate.eval(deleted)
            delete(deleted)
          end
        end
      end

      subscribe do
        operand.on_tuple_update do |tuple, attribute, old_value, new_value|
          if predicate.eval(tuple)
            if tuples.include?(tuple)
              tuple_update_subscription_node.call(tuple, attribute, old_value, new_value)
            else
              insert(tuple)
            end
          else
            delete(tuple)
          end
        end
      end

      def initialize(operand, predicate)
        super()
        @operand, @predicate = operand, predicate
      end

      def merge(tuples)
        operand.merge(tuples)
      end

      def tuple_class
        operand.tuple_class
      end

      def new_tuple(attributes)
        operand.new_tuple(attributes)
      end

      def to_arel
        operand.to_arel.where(predicate.to_arel)
      end

      def set
        operand.set
      end

      def composed_sets
        operand.composed_sets
      end

      def inspect
        "#{operand.inspect}.where(#{predicate.inspect})"
      end

      protected
      def initial_read
        operand.tuples.select do |tuple|
          predicate.eval(tuple)
        end
      end
    end
  end
end