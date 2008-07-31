module Unison
  module Tuple
    include Unison
    include Retainable
    module ClassMethods
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

    attr_reader :nested_tuples

    def initialize
      @update_subscriptions = []
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
      Subscription.new(update_subscriptions, &block)
    end

    protected
    attr_reader :signals, :update_subscriptions

    def trigger_on_update(attribute, old_value, new_value)
      update_subscriptions.each do |subscription|
        subscription.call(attribute, old_value, new_value)
      end
      new_value
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
        raise ArgumentError, "attribute_for only accepts an Attribute or Symbol"
      end
    end
  end
end