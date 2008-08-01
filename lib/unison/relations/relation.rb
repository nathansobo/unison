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
        @insert_subscription_node = SubscriptionNode.new
        @delete_subscription_node = SubscriptionNode.new
        @tuple_update_subscription_node = SubscriptionNode.new
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
        insert_subscription_node.subscribe(&block)
      end

      def on_delete(&block)
        delete_subscription_node.subscribe(&block)
      end

      def on_tuple_update(&block)
        tuple_update_subscription_node.subscribe(&block)
      end

      def inspect
        "<#{self.class} @insert_subscription_node.length=#{insert_subscription_node.length} @delete_subscription_node.length=#{delete_subscription_node.length} @tuple_update_subscription_node.length=#{tuple_update_subscription_node.length}>"
      end

      def ==(other)
        if other.is_a?(self.class)
          read == other.read
        else
          method_missing(:==, other)
        end
      end

      protected
      attr_reader :tuples, :insert_subscription_node, :delete_subscription_node, :tuple_update_subscription_node

      def method_missing(method_name, *args, &block)
        if singleton?
          read.first.send(method_name, *args, &block)
        else
          read.send(method_name, *args, &block)
        end
      end

      def trigger_on_insert(inserted)
        insert_subscription_node.call(inserted)
      end

      def trigger_on_delete(deleted)
        delete_subscription_node.call(deleted)
      end

      def trigger_on_tuple_update(updated_tuple, attribute, old_value, new_value)
        tuple_update_subscription_node.call(updated_tuple, attribute, old_value, new_value)
      end
    end
  end
end