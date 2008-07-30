module Unison
  module Relations
    class Selection < Relation
      attr_reader :operand, :predicate, :operand_subscriptions, :predicate_subscription

      def initialize(operand, predicate)
        super()
        @operand_subscriptions = []
        @operand, @predicate = operand, predicate
        predicate.retain(self)
        operand.retain(self)
        @tuples = initial_read

        @predicate_subscription =
          predicate.on_update do
            new_tuples = initial_read
            deleted_tuples = tuples - new_tuples
            inserted_tuples = new_tuples - tuples
            tuples.clear
            tuples.concat initial_read
            deleted_tuples.each do |deleted_tuple|
              trigger_on_delete(deleted_tuple)
            end
            inserted_tuples.each do |inserted_tuple|
              trigger_on_insert(inserted_tuple)
            end
          end

        operand_subscriptions.push(
          operand.on_insert do |created|
            if predicate.eval(created)
              tuples.push(created)
              trigger_on_insert(created)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_delete do |deleted|
            if predicate.eval(deleted)
              tuples.delete(deleted)
              trigger_on_delete(deleted)
            end
          end
        )

        operand_subscriptions.push(
          operand.on_tuple_update do |tuple, attribute, old_value, new_value|
            if predicate.eval(tuple)
              if tuples.include?(tuple)
                trigger_on_tuple_update(tuple, attribute, old_value, new_value)
              else
                tuples.push(tuple)
                trigger_on_insert(tuple)
              end
            else
              tuples.delete(tuple)
              trigger_on_delete(tuple)
            end
          end
        )
      end

      def ==(other)
        return false unless other.instance_of?(Selection)
        operand == other.operand && predicate == other.predicate
      end

      def read
        tuples
      end

      def size
        read.size
      end

      protected
      attr_reader :tuples

      def initial_read
        operand.read.select do |tuple|
          predicate.eval(tuple)
        end
      end

      def destroy
        predicate_subscription.destroy
        operand_subscriptions.each do |subscription|
          subscription.destroy
        end
        predicate.release self
        operand.release self
      end
    end
  end
end