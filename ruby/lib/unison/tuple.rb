module Unison
  module Tuple
    include Unison
    include Retainable
    module ClassMethods
      include Retainable::ClassMethods
      def [](attribute)
        set[attribute]
      end

      def where(predicate)
        set.where(predicate)
      end

      def find(id)
        set.find(id)
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
      @new = true
    end

    def persisted
      @new = false
    end

    def new?
      @new
    end
    
    def set
      self.class.set
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
      unless set.has_attribute?(attribute_or_name)
        raise ArgumentError, "Attribute #{attribute_or_name.inspect} must be part of the Tuple's Set"
      end
      case attribute_or_name
      when Attribute
        attribute_or_name
      when Symbol
        set[attribute_or_name]
      else
        raise ArgumentError, "attribute_for only accepts an Attribute or Symbol"
      end
    end
  end
end