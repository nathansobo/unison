module Unison
  module Signals
    class Signal
      include Retainable

      def initialize
        @change_subscription_node = SubscriptionNode.new(self)
      end

      def on_change(*args, &block)
        change_subscription_node.subscribe(*args, &block)
      end

      def to_arel
        value.to_arel
      end

      def signal(&block)
        raise ArgumentError, "You must pass a transform block to make a DerivedSignal" unless block
        DerivedSignal.new(self, &block)
      end

      protected
      attr_reader :change_subscription_node
    end
  end
end