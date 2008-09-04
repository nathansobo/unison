module Unison
  class SubscriptionNode < Array
    attr_reader :owner

    def initialize(owner)
      @owner = owner
    end
    
    def subscribe(subscriber=nil, &block)
      subscriber ||= eval("self", block)
      unless owner.retained_by?(subscriber)
        raise ArgumentError, "Subscriber must retain the owner of the SubscriptionNode"
      end
      Subscription.new(self, &block)
    end

    def call(*args)
      each do |subscription|
        subscription.call(*args)
      end
      args
    end
  end
end