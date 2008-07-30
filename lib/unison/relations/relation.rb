module Unison
  module Relations
    class Relation
      include Retainable
      attr_writer :tuple_class
      def initialize
        tuple_class.relation = self
        @insert_subscriptions = []
        @delete_subscriptions = []
        @tuple_update_subscriptions = []
        @singleton = false
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

      def treat_as_singleton
        @singleton = true
      end

      def singleton?
        @singleton
      end

      def on_insert(&block)
        Subscription.new(insert_subscriptions, &block)
      end

      def on_delete(&block)
        Subscription.new(delete_subscriptions, &block)
      end

      def on_tuple_update(&block)
        Subscription.new(tuple_update_subscriptions, &block)
      end

      def inspect
        "<#{self.class} @insert_subscriptions.length=#{insert_subscriptions.length} @delete_subscriptions.length=#{delete_subscriptions.length}>"
      end

      protected
      attr_reader :insert_subscriptions, :delete_subscriptions, :tuple_update_subscriptions

      def method_missing(method_name, *args, &block)
        if singleton?
          read.first.send(method_name, *args, &block)
        else
          super
        end
      end

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

      def trigger_on_tuple_update(updated_tuple, attribute, old_value, new_value)
        tuple_update_subscriptions.each do |subscription|
          subscription.call(updated_tuple, attribute, old_value, new_value)
        end
        updated_tuple
      end
    end
  end
end