module Unison
  class Signal
    include Retainable
    attr_reader :tuple, :attribute

    retains :tuple

    def initialize(tuple, attribute)
      @tuple, @attribute = tuple, attribute
      @update_subscription_node = SubscriptionNode.new
      @tuple_subscription = nil
    end

    def value
      tuple[attribute]
    end

    def on_update(&block)
      update_subscription_node.subscribe(&block)
    end

    protected
    attr_reader :update_subscription_node, :tuple_subscription

    def after_first_retain
      @tuple_subscription =
        tuple.on_update do |updated_attribute, old_value, new_value|
          if attribute == updated_attribute
            update_subscription_node.call(tuple, old_value, new_value)
          end
        end
    end

    def destroy
      raise "Signal #{self.inspect} is not registered on its Tuple" unless tuple.send(:signals)[attribute] == self
      tuple.send(:signals).delete(attribute)
      tuple.release(self)
    end
  end
end