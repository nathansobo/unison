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
        @tuples = nil
      end

      def [](index)
        case index
        when Symbol
          attribute(index)
        when Integer
          delegate_to_read(:[], index)
        else
          raise ArgumentError, "[] does not support #{index.inspect} as an argument"
        end
      end

      def find(id)
        where(self[:id].eq(id)).singleton
      end

      def where(predicate)
        Selection.new(self, predicate)
      end

      def read
        retained?? tuples : initial_read
      end

      def nil?
        singleton?? read.first.nil? : false
      end

      def singleton
        @singleton = true
        self
      end

      def singleton?
        @singleton
      end

      def on_insert(&block)
        raise "Relation must be retained" unless retained?
        insert_subscription_node.subscribe(&block)
      end

      def on_delete(&block)
        raise "Relation must be retained" unless retained?
        delete_subscription_node.subscribe(&block)
      end

      def on_tuple_update(&block)
        raise "Relation must be retained" unless retained?
        tuple_update_subscription_node.subscribe(&block)
      end

      def inspect
        "<#{self.class}:#{object_id} @insert_subscription_node.length=#{insert_subscription_node.length} @delete_subscription_node.length=#{delete_subscription_node.length} @tuple_update_subscription_node.length=#{tuple_update_subscription_node.length}>"
      end

      def ==(other)
        if other.is_a?(Relation)
          read == other.read
        else
          delegate_to_read(:==, other)
        end
      end

      protected
      attr_reader :insert_subscription_node, :delete_subscription_node, :tuple_update_subscription_node

      def tuples
        raise "Relation must be retained in order to refer to memoized tuples" unless retained?
        return @tuples if @tuples
        @tuples = []
        initial_read.each do |tuple|
          insert(tuple)
        end
        @tuples
      end

      def insert(tuple)
        raise "Relation must be retained" unless retained?
        tuples.push(tuple)
        insert_subscription_node.call(tuple)
        tuple
      end

      def after_first_retain
        tuples
      end

      def initial_read
        raise NotImplementedError
      end

      def method_missing(method_name, *args, &block)
        delegate_to_read(method_name, *args, &block)
      end

      def delegate_to_read(method_name, *args, &block)
        if singleton?
          read.first.send(method_name, *args, &block)
        else
          read.send(method_name, *args, &block)
        end
      end
    end
  end
end