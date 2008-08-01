module Unison
  module Predicates
    class Base
      include Retainable

      def initialize
        @update_subscriptions = []
      end

      def eval(tuple)
        raise NotImplementedError
      end

      def ==(other)
        self.object_id == other.object_id
      end

      def on_update(&block)
        Subscription.new(update_subscriptions, &block)
      end

      protected
      attr_reader :update_subscriptions

      def trigger_on_update
        update_subscriptions.each do |subscription|
          subscription.call
        end
      end
    end
  end
end