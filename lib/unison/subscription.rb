module Unison
  class Subscription
    attr_reader :subscription_node
    def initialize(subscription_node, &proc)
      raise ArgumentError, "Subscription needs a block to execute" unless proc
      @subscription_node = subscription_node
      @proc = proc
      subscription_node.push(self)
    end

    def call(*args)
      proc.call(*args)
      args
    end
    alias_method :trigger, :call
    
    def destroy
      subscription_node.delete(self)
    end

    protected
    attr_reader :proc
  end
end