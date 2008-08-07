module Unison
  module PrimitiveTuple
    include Tuple
    module ClassMethods
      include Tuple::ClassMethods
      attr_accessor :relation

      def member_of(relation)
        @relation = relation.retain(self)
        relation.tuple_class = self
      end

      def attribute(name, type)
        relation.attribute(name, type)
      end

      def attribute_reader(name, type)
        attribute = relation.attribute(name, type)
        define_method(name) do
          self[attribute]
        end
      end

      def attribute_writer(name, type)
        attribute = relation.attribute(name, type)
        define_method("#{name}=") do |value|
          self[attribute] = value
        end
      end

      def attribute_accessor(name, type)
        attribute_reader(name, type)
        attribute_writer(name, type)
      end

      def relates_to_n(name, &definition)
        instance_relations.push [name, definition]
        attr_reader name
      end

      def relates_to_1(name, &definition)
        singleton_instance_relations.push [name, definition]
        attr_reader name
      end

      def has_many(name, options={})
        relates_to_n(name) do
          class_name = options[:class_name] || name.to_s.singularize.classify
          target_relation = class_name.to_s.constantize.relation
          select_children(target_relation, :foreign_key => options[:foreign_key])
        end
      end

      def has_one(name, options={})
        relates_to_1(name) do
          class_name = options[:class_name] || name.to_s.classify
          select_child class_name.to_s.constantize, options
        end
      end

      def belongs_to(name, options = {})
        relates_to_1(name) do
          class_name = options[:class_name] || name.to_s.classify
          foreign_key = options[:foreign_key] || :"#{name}_id"
          select_parent(class_name.to_s.constantize.relation, :foreign_key => foreign_key)
        end
      end

      def create(attributes)
        relation.insert(new(attributes))
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

    attr_reader :attributes

    def initialize(attributes={})
      super()
      @signals = {}
      @primitive = true
      @attributes = attributes
      attributes.each do |attribute, value|
        self[attribute] = value
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

    def [](attribute)
      attributes[attribute_for(attribute)]
    end    

    def []=(attribute_or_symbol, value)
      attribute = attribute_for(attribute_or_symbol)
      old_value = attributes[attribute]
      attributes[attribute] = value
      update_subscription_node.call(attribute, old_value, value)
      value
    end

    def ==(other)
      return false unless other.is_a?(PrimitiveTuple)
      attributes == other.attributes
    end
    
    def primitive?
      true
    end

    def compound?
      false
    end

    def select_children(target_relation, options={})
      foreign_key = options[:foreign_key] || :"#{self.class.name.to_s.underscore}_id"
      target_relation.where(target_relation[foreign_key].eq(self[:id]))
    end

    def select_child(target_relation, options={})
      foreign_key = options[:foreign_key] || :"#{self.class.name.to_s.underscore}_id"
      target_relation.where(target_relation[foreign_key].eq(self[:id])).treat_as_singleton
    end

    def select_parent(target_relation, options={})
      foreign_key = options[:foreign_key] || :"#{target_relation.name.to_s.singularize.underscore}_id"
      target_relation.where(target_relation[:id].eq(self[foreign_key])).treat_as_singleton
    end

    def signal(attribute_or_symbol)
      attribute = attribute_for(attribute_or_symbol)
      signals[attribute] ||= Signal.new(self, attribute)
    end

    protected
    def instance_relations
      self.class.send(:instance_relations)
    end

    def singleton_instance_relations
      self.class.send(:singleton_instance_relations)
    end

    public
    class Base
      include PrimitiveTuple
    end
  end
end