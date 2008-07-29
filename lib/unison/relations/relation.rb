module Unison
  module Relations
    class Relation
      attr_writer :tuple_class
      def initialize
        tuple_class.relation = self
        @insert_subscriptions = []
        @delete_subscriptions = []
      end
      
      def tuple_class
        @tuple_class ||= Class.new(Unison::Tuple::Base)
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

      def on_delete(&block)
        raise ArgumentError, "#on_delete needs a block passed in" unless block
        delete_subscriptions << block
      end

      protected
      attr_reader :insert_subscriptions, :delete_subscriptions

      def trigger_on_insert(inserted)
        insert_subscriptions.each do |subscription|
          subscription.call(inserted)
        end
        inserted
      end

      def trigger_on_delete(deleted)
        delete_subscriptions.each do |subscription|
          subscription.call(deleted)
        end
        deleted
      end
    end
  end
end