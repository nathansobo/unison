module Unison
  module Relations
    class Relation
      attr_writer :tuple_class
      def initialize
        tuple_class.relation = self
        @insert_subscriptions = []
      end
      
      def tuple_class
        @tuple_class ||= Class.new(Tuple::Base)
      end

      def where(predicate)
        Selection.new(self, predicate)
      end

      def first
        read.first
      end

      def on_insert(&block)
        raise ArgumentError, "#on_insert needs a block passed in" unless block
        insert_subscriptions << block
      end

      protected
      attr_reader :insert_subscriptions
    end
  end
end