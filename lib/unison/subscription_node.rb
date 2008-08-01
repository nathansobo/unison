module Unison
  class SubscriptionNode < Array
    def subscribe(&block)
      Subscription.new(self, &block)
    end

    def call(*args)
      each do |subscription|
        subscription.call(*args)
      end
    end
    alias_method :trigger, :call
  end
end