module Unison
  module Predicates
    class Base
      include Retainable

      def eval(tuple)
        raise NotImplementedError
      end

      def ==(other)
        self == other
      end
    end
  end
end