module Unison
  class Signal
    include Retainable
    attr_reader :tuple, :attribute

    retains :tuple

    def initialize(tuple, attribute)
      @tuple, @attribute = tuple, attribute
      @update_subscription_node = SubscriptionNode.new
    end

    def value
      tuple[attribute]
    end

    def on_update(&block)
      update_subscription_node.subscribe(&block)
    end

    def to_arel
      value.to_arel
    end

    protected
    attr_reader :update_subscription_node

    def after_first_retain
      subscriptions.push(
        tuple.on_update do |updated_attribute, old_value, new_value|
          if attribute == updated_attribute
            update_subscription_node.call(tuple, old_value, new_value)
          end
        end
      )
    end
  end
end