module Unison
  module Relations
    class Selection < Relation
      attr_reader :operand, :predicate

      def initialize(operand, predicate)
        @operand, @predicate = operand, predicate
        @tuples = initial_read
      end

      def ==(other)
        return false unless other.instance_of?(Selection)
        operand == other.operand && predicate == other.predicate
      end

      def read
        tuples
      end

      def size
        read.size
      end

      def mailbox=(mailbox)
        mailbox.subscribe(operand, :insert) do |tuple|
          tuples.push(tuple) if predicate.call(tuple)
        end
      end

      protected
      attr_reader :tuples

      def initial_read
        operand.read.select do |tuple|
          predicate.call(tuple)
        end
      end

    end
  end
end