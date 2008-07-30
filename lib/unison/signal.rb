module Unison
  class Signal
    include Retainable
    attr_reader :tuple, :attribute
    def initialize(tuple, attribute)
      @tuple, @attribute = tuple, attribute
      @update_subscriptions = []
    end

    def value
      tuple[attribute]
    end

    def on_update(&block)
      Subscription.new(update_subscriptions, &block)
    end

    def trigger_on_update(old_value, new_value)
      update_subscriptions.each do |subscription|
        subscription.call(tuple, old_value, new_value)
      end
      new_value
    end

    protected
    attr_reader :update_subscriptions
  end
end