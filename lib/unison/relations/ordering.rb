module Unison
  module Relations
    class Ordering < Relation
      attr_reader :operand, :attribute, :operand_subscriptions

      retains :operand

      def initialize(operand, attribute)
        super()
        @operand, @attribute = operand, attribute
        @operand_subscriptions = []
      end

      def tuple_class
        operand.tuple_class
      end

      protected

      def after_first_retain
        super
        operand_subscriptions.push(
          operand.on_insert do |inserted|
            insert(inserted)
          end
        )
        operand_subscriptions.push(
          operand.on_delete do |inserted|
            delete(inserted)
          end
        )
      end

      def after_last_release
        super
        operand_subscriptions.each do |subscription|
          subscription.destroy
        end
        operand.release self
      end

      def add_to_tuples(tuple_to_add)
        super
        tuples.sort! {|tuple_a, tuple_b| tuple_a[attribute] <=> tuple_b[attribute]}
      end

      def initial_read
        operand.tuples.sort_by {|tuple| tuple[attribute]}
      end
    end
  end
end
