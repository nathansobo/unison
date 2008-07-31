module Unison
  module Relations
    class Relation
      instance_methods.each do |m|
        unless m =~ /(^__|^methods$|^respond_to\?$|^instance_of\?$|^equal\?$|^is_a\?$|^extend$|^class$|^nil\?$|^send$|^object_id$|^should)/
          undef_method m
        end
      end

      include Retainable
      def initialize
        @insert_subscriptions = []
        @delete_subscriptions = []
        @tuple_update_subscriptions = []
        @singleton = false
      end

      def where(predicate)
        Selection.new(self, predicate)
      end

      def read
        tuples
      end

      def nil?
        singleton?? read.first.nil? : false
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

      def ==(other)
        if other.is_a?(self.class)
          read == other.read
        else
          method_missing(:==, other)
        end
      end

      protected
      attr_reader :tuples, :insert_subscriptions, :delete_subscriptions, :tuple_update_subscriptions

      def method_missing(method_name, *args, &block)
        if singleton?
          read.first.send(method_name, *args, &block)
        else
          read.send(method_name, *args, &block)
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