module Unison
  class Signal
    attr_reader :tuple, :attribute
    def initialize(tuple, attribute)
      @tuple, @attribute = tuple, attribute
      @update_subscriptions = []
    end

    def on_update(&block)
      raise ArgumentError, "#on_update needs a block passed in" unless block
      update_subscriptions.push(block)
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