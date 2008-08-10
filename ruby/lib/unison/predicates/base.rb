module Unison
  module Predicates
    class Base
      include Retainable

      def initialize
        @update_subscription_node = SubscriptionNode.new
      end

      def eval(tuple)
        raise NotImplementedError
      end

      def ==(other)
        self.object_id == other.object_id
      end

      def on_update(&block)
        update_subscription_node.subscribe(&block)
      end

      protected
      attr_reader :update_subscription_node
    end
  end
end