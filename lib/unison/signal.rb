module Unison
  class Signal
    include Retainable

    def initialize
      @update_subscription_node = SubscriptionNode.new(self)
    end

    def on_change(*args, &block)
      update_subscription_node.subscribe(*args, &block)
    end

    def to_arel
      value.to_arel
    end

    protected
    attr_reader :update_subscription_node
  end
end