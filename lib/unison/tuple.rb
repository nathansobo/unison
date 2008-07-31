module Unison
  module Tuple
    include Unison
    include Retainable
    module ClassMethods
      attr_accessor :relation

      def member_of(relation)
        @relation = relation
        relation.tuple_class = self
      end

      def attribute(name)
        relation.attribute(name)
      end

      def [](attribute)
        relation[attribute]
      end

      def where(predicate)
        relation.where(predicate)
      end

      def relates_to_n(name, &definition)
        instance_relations.push [name, definition]
        attr_reader name
      end

      def relates_to_1(name, &definition)
        singleton_instance_relations.push [name, definition]
        attr_reader name
      end
      
      def has_many(name)
        relates_to_n(name) do
          self.class.foreign_key_selection self, name.to_s.singularize.classify.constantize
        end
      end

      def has_one(name)
        relates_to_1(name) do
          self.class.foreign_key_selection self, name.to_s.classify.constantize
        end
      end

      def foreign_key_selection(instance, target_class)
        target_relation = target_class.relation
        foreign_key = :"#{name.underscore}_id"
        target_relation.where(target_relation[foreign_key].eq(instance[:id]))
      end

      def find(id)
        relation.where(relation[:id].eq(id)).first
      end

      def create(attributes)
        relation.insert(new(attributes))
      end

      def basename
        name.split("::").last
      end

      protected
      def instance_relations
        @instance_relations ||= []
      end

      def singleton_instance_relations
        @singleton_instance_relations ||= []
      end
    end

    def self.included(a_module)
      a_module.extend ClassMethods
    end

    attr_reader :attributes, :nested_tuples

    def initialize(*args)
      @signals = {}
      @update_subscriptions = []
      if attributes_hash?(args)
        @primitive = true
        @attributes = {}
        args.first.each do |attribute, value|
          self[attribute] = value
        end
      else
        @primitive = false
        @nested_tuples = args
      end

      instance_relations.each do |name, proc|
        relation = instance_eval(&proc)
        instance_variable_set("@#{name}", relation)
      end

      singleton_instance_relations.each do |name, definition|
        relation = instance_eval(&definition)
        relation.treat_as_singleton
        instance_variable_set("@#{name}", relation)
      end
    end
    
    def relation
      self.class.relation
    end

    def primitive?
      @primitive
    end

    def compound?
      !primitive?
    end

    def [](attribute)
      if primitive?
        attributes[attribute_for(attribute)]
      else
        nested_tuples.each do |tuple|
          return tuple if tuple.relation == attribute
          return tuple[attribute] if tuple.relation.has_attribute?(attribute)
        end
        raise ArgumentError, "Attribute #{attribute} not found"
      end
    end

    def []=(attribute_or_symbol, value)
      attribute = attribute_for(attribute_or_symbol)
      old_value = attributes[attribute]
      attributes[attribute] = value
      signals[attribute].trigger_on_update(old_value, value) if signals[attribute]
      trigger_on_update(attribute, old_value, value)
      value
    end

    def ==(other)
      if primitive?
        attributes == other.attributes
      else
        nested_tuples == other.nested_tuples
      end
    end

    def bind(expression)
      case expression
      when Attribute
        self[expression]
      else
        expression
      end
    end

    def signal(attribute_or_symbol)
      raise NotImplementedError, "You can only call #signal on primitive Tuples" unless primitive?
      attribute = attribute_for(attribute_or_symbol)
      signals[attribute] ||= Signal.new(self, attribute)
    end

    def on_update(&block)
      Subscription.new(update_subscriptions, &block)
    end

    def trigger_on_update(old_value, new_value)
      update_subscriptions.each do |subscription|
        subscription.call(tuple, old_value, new_value)
      end
      new_value
    end

    class Base
      include Tuple
    end

    protected
    attr_reader :signals, :update_subscriptions

    def trigger_on_update(attribute, old_value, new_value)
      update_subscriptions.each do |subscription|
        subscription.call(attribute, old_value, new_value)
      end
    end

    def attribute_for(attribute_or_name)
      case attribute_or_name
      when Attribute
        unless relation.has_attribute?(attribute_or_name)
          raise ArgumentError, "Attribute must be part of the Tuple's Relation"
        end
        attribute_or_name
      when Symbol
        relation[attribute_or_name]
      else
        raise "Attributes must be Attributes or Symbols"
      end
    end

    def attributes_hash?(args)
      args.size == 1 && args.first.instance_of?(Hash)
    end

    def instance_relations
      self.class.send(:instance_relations)
    end

    def singleton_instance_relations
      self.class.send(:singleton_instance_relations)
    end
  end
end