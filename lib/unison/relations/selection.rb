module Unison
  module Relations
    class Selection < Relation
      attr_reader :operand, :predicate

      def initialize(operand, predicate)
        super()
        @operand, @predicate = operand, predicate
        @tuples = initial_read

        operand.on_insert do |created|
          if predicate.eval(created)
            tuples.push(created)
            insert_subscriptions.each do |subscription|
              subscription.call(created)
            end
          end
        end
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

      protected
      attr_reader :tuples

      def initial_read
        operand.read.select do |tuple|
          predicate.eval(tuple)
        end
      end

    end
  end
end