module Unison
  module Predicates
    class Eq < Base
      attr_reader :operand_1, :operand_2
      def initialize(operand_1, operand_2)
        @operand_1, @operand_2 = operand_1, operand_2
        @operand_subscriptions = []
        subscribe_to_operand_update_if_signal operand_1
        subscribe_to_operand_update_if_signal operand_2
        @update_subscriptions = []
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

      def on_update(&block)
        Subscription.new(update_subscriptions, &block)
      end

      protected
      attr_reader :operand_subscriptions

      def destroy
        operand_subscriptions.each do |subscription|
          subscription.destroy
        end
        operand_1.release(self) if operand_1.is_a?(Signal)
        operand_2.release(self) if operand_2.is_a?(Signal)
      end

      def eval_operand(operand)
        operand.is_a?(Signal) ? operand.value : operand
      end

      def subscribe_to_operand_update_if_signal(operand)
        if operand.is_a?(Signal)
          operand.retain(self)
          operand_subscriptions.push(
            operand.on_update do
              trigger_on_update
            end
          )
        end
      end

      def trigger_on_update
        update_subscriptions.each do |subscription|
          subscription.call
        end
      end

      attr_reader :update_subscriptions
    end
  end
end