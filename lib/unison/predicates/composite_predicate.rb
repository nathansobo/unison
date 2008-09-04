module Unison
  module Predicates
    class CompositePredicate < Base
      attr_reader :operands
      def initialize(*operands)
        raise ArgumentError, "And predicate must have at least one child Predicate" if operands.empty?
        super()
        @operands = operands
        @child_predicate_subscriptions = []
      end

      def ==(other)
        if other.is_a?(self.class)
          operands == other.operands
        else
          false
        end
      end

      protected
      attr_reader :child_predicate_subscriptions

      def after_first_retain
        operands.each do |child_predicate|
          child_predicate.retained_by(self)
          child_predicate_subscriptions.push(
            child_predicate.on_update do
              update_subscription_node.call
            end
          )
        end        
      end

      def after_last_release
        child_predicate_subscriptions.each do |subscription|
          subscription.destroy
        end

        operands.each do |child_predicate|
          child_predicate.released_by self
        end
      end
    end
  end
end