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

      def fetch_arel
        value.fetch_arel
      end

      def signal(method_name=nil, &block)
        DerivedSignal.new(self, method_name, &block)
      end

      protected
      attr_reader :change_subscription_node
    end
  end
end