module Unison
  module Tuples
    class Tuple
      include Unison
      include Retainable      
      class << self
        def [](attribute)
          set[attribute]
        end

        def basename
          name.split("::").last
        end
      end

      def initialize
        @update_subscription_node = SubscriptionNode.new(self)
      end

      def bind(expression)
        case expression
        when Attributes::Attribute
          self[expression]
        else
          expression
        end
      end

      def on_update(*args, &block)
        update_subscription_node.subscribe(*args, &block)
      end

      protected
      attr_reader :update_subscription_node
    end    
  end
end