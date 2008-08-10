module Unison
  class Signal
    include Retainable
    attr_reader :tuple, :attribute
    def initialize(tuple, attribute)
      @tuple, @attribute = tuple, attribute
      @update_subscription_node = SubscriptionNode.new
      tuple.retain(self)
    end

    def value
      tuple[attribute]
    end

    def on_update(&block)
      update_subscription_node.subscribe(&block)
    end

    def trigger_on_update(old_value, new_value)
      update_subscription_node.call(tuple, old_value, new_value)
    end

    protected
    attr_reader :update_subscription_node

    def destroy
      raise "Signal #{self.inspect} is not registered on its Tuple" unless tuple.send(:signals)[attribute] == self
      tuple.send(:signals).delete(attribute)
      tuple.release(self)
    end
  end
end