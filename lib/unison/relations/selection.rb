module Unison
  module Relations
    class Selection < Relation
      attr_reader :operand, :predicate

      def initialize(operand, predicate)
        @operand, @predicate = operand, predicate
      end

      def read
        operand.read.select do |tuple|
          predicate.call(tuple)
        end
      end
    end
  end
end