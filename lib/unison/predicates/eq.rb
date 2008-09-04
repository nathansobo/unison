module Unison
  module Predicates
    class Eq < Base
      attr_reader :operand_1, :operand_2
      def initialize(operand_1, operand_2)
        super()
        @operand_1, @operand_2 = operand_1, operand_2
        @subscriptions = []
      end

      def ==(other)
        if other.instance_of?(Eq)
          operand_1 == other.operand_1 && operand_2 == other.operand_2
        else
          false
        end
      end

      def eval(tuple)
        tuple.bind(eval_operand(operand_1)) == tuple.bind(eval_operand(operand_2))
      end

      def to_arel
        Arel::Equality.new(operand_1.to_arel, operand_2.to_arel)
      end

      protected
      attr_reader :subscriptions
      
      def after_first_retain
        subscribe_to_operand_update_if_signal operand_1
        subscribe_to_operand_update_if_signal operand_2
      end

      def subscribe_to_operand_update_if_signal(operand)
        if operand.is_a?(Signal)
          operand.retained_by(self)
          subscriptions.push(
            operand.on_update do
              update_subscription_node.call
            end
          )
        end
      end

      def after_last_release
        subscriptions.each do |subscription|
          subscription.destroy
        end
        operand_1.released_by(self) if operand_1.is_a?(Signal)
        operand_2.released_by(self) if operand_2.is_a?(Signal)
      end

      def eval_operand(operand)
        operand.is_a?(Signal) ? operand.value : operand
      end
    end
  end
end