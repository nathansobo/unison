module Unison
  module Relations
    class Relation
      attr_writer :tuple_class
      def initialize
        tuple_class.relation = self
        @insert_subscriptions = []
        @delete_subscriptions = []
        @tuple_update_subscriptions = []
        @singleton = false
        @retainers = {}
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

      def retain(retainer)
        raise ArgumentError, "Object #{retainer.inspect} has already retained this Object" if retained_by?(retainer)
        retainers[retainer.object_id] = retainer
      end

      def release(retainer)
        retainers.delete(retainer.object_id)
        destroy if refcount == 0
      end

      def refcount
        retainers.length
      end

      def retained_by?(potential_retainer)
        retainers[potential_retainer.object_id] ? true : false
      end

      protected
      attr_reader :insert_subscriptions, :delete_subscriptions, :tuple_update_subscriptions, :retainers

      def method_missing(method_name, *args, &block)
        if singleton?
          read.first.send(method_name, *args, &block)
        else
          super
        end
      end

      def destroy
        
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