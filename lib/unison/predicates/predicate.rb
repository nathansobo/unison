module Unison
  module Predicates
    class Predicate < Base
      attr_reader :proc
      
      def initialize(&block)
        raise ArgumentError, "Predicate must take a block" unless block
        @proc = block
      end

      def eval(tuple)
        proc.call(tuple)
      end

      def ==(other)
        if other.is_a?(Predicate)
          proc == other.proc
        else
          false
        end
      end
    end
  end
end