module Unison
  module Tuple
    include Unison
    include Retainable
    module ClassMethods
      include Retainable::ClassMethods
      def [](attribute)
        relation[attribute]
      end

      def where(predicate)
        relation.where(predicate)
      end

      def find(id)
        relation.where(relation[:id].eq(id)).first
      end

      def basename
        name.split("::").last
      end
    end
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    attr_reader :nested_tuples

    def initialize
      @update_subscription_node = SubscriptionNode.new
    end
    
    def relation
      self.class.relation
    end

    def bind(expression)
      case expression
      when Attribute
        self[expression]
      else
        expression
      end
    end

    def on_update(&block)
      update_subscription_node.subscribe(&block)
    end

    protected
    attr_reader :signals, :update_subscription_node

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
        raise ArgumentError, "attribute_for only accepts an Attribute or Symbol"
      end
    end
  end
end