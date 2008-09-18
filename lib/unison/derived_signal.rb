module Unison
  class DerivedSignal
    include Retainable

    retain :source_signal
    subscribe do
      source_signal.on_update do |source_old_value, source_new_value|
        old_value = @value || transform.call(source_old_value)
        @value = transform.call(source_new_value)
        update_subscription_node.call(old_value, value)
      end
    end

    attr_reader :source_signal, :transform
    def initialize(source_signal, &transform)
      @source_signal, @transform = source_signal, transform
      @update_subscription_node = SubscriptionNode.new(self)
    end

    def value
      @value ||= transform.call(source_signal.value)
    end

    def on_update(*args, &block)
      update_subscription_node.subscribe(*args, &block)
    end

    protected
    attr_reader :update_subscription_node

  end
end
