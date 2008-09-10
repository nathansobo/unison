module Unison
  class Signal
    include Retainable
    attr_reader :tuple, :attribute

    retain :tuple
    subscribe do
      tuple.on_update do |updated_attribute, old_value, new_value|
        if attribute == updated_attribute
          update_subscription_node.call(tuple, old_value, new_value)
        end
      end
    end

    def initialize(tuple, attribute)
      @tuple, @attribute = tuple, attribute
      @update_subscription_node = SubscriptionNode.new(self)
    end

    def value
      tuple[attribute]
    end

    def on_update(*args, &block)
      update_subscription_node.subscribe(*args, &block)
    end

    def to_arel
      value.to_arel
    end

    def ==(other)
      return false unless other.is_a?(Signal)
      other.attribute == attribute && other.tuple == tuple
    end

    protected
    attr_reader :update_subscription_node
  end
end