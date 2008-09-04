module Unison
  module Predicates
    class Base
      include Retainable

      def initialize
        @update_subscription_node = SubscriptionNode.new(self)
      end

      def eval(tuple)
        raise NotImplementedError
      end

      def ==(other)
        self.object_id == other.object_id
      end

      def on_update(*args, &block)
        update_subscription_node.subscribe(*args, &block)
      end

      protected
      attr_reader :update_subscription_node
    end
  end
end