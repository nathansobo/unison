module Unison
  module Relations
    class Relation
      instance_methods.each do |m|
        unless m =~ /(^__|^methods$|^respond_to\?$|^instance_of\?$|^equal\?$|^is_a\?$|^extend$|^class$|^nil\?$|^send$|^object_id$|^should|^instance_eval$)/
          undef_method m
        end
      end

      include Retainable
      def initialize
        @insert_subscription_node = SubscriptionNode.new(self)
        @delete_subscription_node = SubscriptionNode.new(self)
        @tuple_update_subscription_node = SubscriptionNode.new(self)
        @singleton = false
        @tuples = nil
      end

      def fetch_sql
        fetch_arel.to_sql
      end

      def [](index)
        case index
        when Symbol
          attribute(index)
        when Integer
          tuples[index]
        else
          raise ArgumentError, "[] does not support #{index.inspect} as an argument"
        end
      end

      def pull
        merge(Unison.origin.fetch(self))
        self
      end

      def push
        if composite?
          composed_sets.each do |component_set|
            Unison.origin.push(self.project(component_set))
          end
        else
          Unison.origin.push(self)
        end
      end

      def fetch
        Unison.origin.fetch(self)
      end

      def find(id_or_predicate)
        find_or_pull(id_or_predicate, false)
      end

      def find_or_pull(id_or_predicate, attempt_pull=true)
        if id_or_predicate.is_a?(Predicates::Base)
          predicate = id_or_predicate
        else
          predicate = self[:id].eq(self[:id].convert(id_or_predicate))
        end
        selection = where(predicate)
        selection.pull if attempt_pull && selection.empty?
        selection.tuples.first
      end

      def where(predicate)
        Selection.new(self, predicate)
      end

      def join(operand_2)
        PartialInnerJoin.new(self, operand_2)
      end

      def project(*attributes)
        if attributes.length == 1 && attributes.first.class == Set
          SetProjection.new(self, attributes.first)
        else
          AttributesProjection.new(self, attributes)
        end
      end
      
      def order_by(*attributes)
        Ordering.new(self, *attributes)
      end

      def tuples
        retained?? @tuples : initial_read
      end

      def composite?
        composed_sets.size > 1
      end

      def singleton
        SingletonRelation.new(self)
      end

      def on_insert(*args, &block)
        raise "Relation must be retained" unless retained?
        insert_subscription_node.subscribe(*args, &block)
      end

      def on_delete(*args, &block)
        raise "Relation must be retained" unless retained?
        delete_subscription_node.subscribe(*args, &block)
      end

      def on_tuple_update(*args, &block)
        raise "Relation must be retained" unless retained?
        tuple_update_subscription_node.subscribe(*args, &block)
      end

      def inspect
        "<#{self.class}:#{object_id}>"
      end

      def ==(other)
        if other.is_a?(Relation)
          tuples == other.tuples
        else
          method_missing(:==, other)
        end
      end

      alias_method :to_ary, :tuples

      protected
      attr_reader :insert_subscription_node, :delete_subscription_node, :tuple_update_subscription_node

      def insert(tuple)
        insert_without_callback(tuple)
        insert_subscription_node.call(tuple)
        tuple
      end

      def insert_without_callback(tuple)
        raise "Relation must be retained" unless retained?
        tuple.retain_with(self)
        add_to_tuples(tuple)
      end

      def add_to_tuples(tuple)
        tuples.push(tuple)
      end

      def delete(tuple)
        delete_without_callback(tuple)
        delete_subscription_node.call(tuple)
        tuple
      end

      def delete_without_callback(tuple)
        tuple.release_from(self)
        tuples.delete(tuple)
      end

      def after_first_retain
        @tuples = []
        initial_read.each do |tuple|
          insert(tuple)
        end
      end

      def after_last_release
        tuples.each do |tuple|
          tuple.release_from(self)
        end
      end

      def initial_read
        raise NotImplementedError
      end

      def method_missing(method_name, *args, &block)
        if method_missing_delegation_target.respond_to?(method_name)
          method_missing_delegation_target.send(method_name, *args, &block)
        else
          super
        end
      end

      def method_missing_delegation_target
        tuples
      end

      class PartialInnerJoin
        attr_reader :operand_1, :operand_2
        def initialize(operand_1, operand_2)
          @operand_1, @operand_2 = operand_1, operand_2
        end

        def on(predicate)
          Relations::InnerJoin.new(operand_1, operand_2, predicate)
        end
      end      
    end
  end
end