module Unison
  module Relations
    class Relation
      attr_writer :tuple_class
      def initialize
        tuple_class.relation = self
      end
      
      def tuple_class
        @tuple_class ||= Class.new(tuple_superclass)
      end

      def tuple_superclass
        CompoundTuple::Base
      end

      def where(predicate)
        Selection.new(self, predicate)
      end

      def first
        read.first
      end
    end
  end
end