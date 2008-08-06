module Unison
  module Predicates
    class CompositePredicate < Base
      attr_reader :child_predicates
      def initialize(*child_predicates)
        raise ArgumentError, "And predicate must have at least one child Predicate" if child_predicates.empty?
        super()
        @child_predicates = child_predicates
        @child_predicate_subscriptions = []

        child_predicates.each do |child_predicate|
          # TODO - Move to after first retain
          child_predicate.retain(self)
          child_predicate_subscriptions.push(
            child_predicate.on_update do
              update_subscription_node.call
            end
          )
        end
      end

      def ==(other)
        if other.is_a?(self.class)
          child_predicates == other.child_predicates
        else
          false
        end
      end

      protected
      attr_reader :child_predicate_subscriptions

      def destroy
        child_predicate_subscriptions.each do |subscription|
          subscription.destroy
        end

        child_predicates.each do |child_predicate|
          child_predicate.release self
        end
      end
    end
  end
end