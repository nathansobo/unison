module Unison
  class Subscription
    attr_reader :event_node
    def initialize(event_node, &proc)
      raise ArgumentError, "Subscription needs a block to execute" unless proc
      @event_node = event_node
      @proc = proc
      event_node.push(self)
    end

    def call(*args)
      proc.call(*args)
    end
    
    def destroy
      event_node.delete(self)
    end

    protected
    attr_reader :proc
  end
end