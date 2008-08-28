module Unison
  module Relations
    class Ordering < Relation
      attr_reader :operand, :attribute

      def initialize(operand, attribute)
        super()
        @operand, @attribute = operand, attribute
      end

      protected

      def initial_read
        operand.tuples.sort_by {|tuple| tuple[attribute]}
      end
    end
  end
end
