module Unison
  module Relations
    class Relation
      attr_reader :tuple_class
      def initialize
        @tuple_class = Class.new(tuple_superclass)
        tuple_class.relation = self
      end

      def tuple_superclass
        CompoundTuple::Base
      end
    end
  end
end