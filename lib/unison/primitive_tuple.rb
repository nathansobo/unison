module Unison
  module PrimitiveTuple
    include Tuple
    include Enumerable
    module ClassMethods
      include Tuple::ClassMethods

      def new(attrs={})
        instance = polymorphic_allocate(attrs)
        instance.send(:initialize, attrs)
        instance
      end

      def polymorphic_allocate(attrs)
        allocate
      end

      def inherited(subclass)
        super
        unless self == PrimitiveTuple::Base
          subclass.foreign_key_name = foreign_key_name
        end
      end

      def foreign_key_name
        @foreign_key_name ||= :"#{name.to_s.underscore}_id"
      end
      attr_writer :foreign_key_name

      def set
        @set || (superclass.respond_to?(:set) ? superclass.set : nil)
      end
      attr_writer :set

      def member_of(set)
        @set = set.retain_with(self)
        set.tuple_class = self
      end

      def default_attribute_values
        @default_attribute_values ||= inheritable_inject(:default_attribute_values, {}) do |defaults, value|
          defaults.merge(value)
        end
      end

      def attribute(name, type, options={})
        attribute = set.has_attribute(name, type)
        if options.has_key?(:default)
          default_attribute_values[attribute] = options[:default]
        end
        attribute
      end

      def attribute_reader(name, type, options={})
        attribute = self.attribute(name, type, options)
        define_method(name) do
          self[attribute]
        end
      end

      def attribute_writer(name, type, options={})
        attribute = self.attribute(name, type, options)
        define_method("#{name}=") do |value|
          self[attribute] = value
        end
      end

      def attribute_accessor(name, type, options={})
        attribute_reader(name, type, options)
        attribute_writer(name, type, options)
      end

      def relates_to_n(name, &definition)
        instance_relation_definitions.push(InstanceRelationDefinition.new(name, definition, caller, false))
        attr_reader name
      end

      def relates_to_1(name, &definition)
        instance_relation_definitions.push(InstanceRelationDefinition.new(name, definition, caller, true))
        attr_reader name
      end

      def has_many(name, options={}, &customization_block)
        relates_to_n(name) do
          class_name = options[:class_name] || name.to_s.classify
          target_relation = class_name.to_s.constantize.set
          relation = if options[:through]
            has_many_through(target_relation, options)
          else
            select_children(target_relation, :foreign_key => options[:foreign_key])
          end
          customization_block ? instance_exec(relation, &customization_block) : relation
        end
      end

      def has_one(name, options={}, &customization_block)
        relates_to_1(name) do
          class_name = options[:class_name] || name.to_s.classify
          relation = select_child class_name.to_s.constantize, options
          customization_block ? instance_exec(relation, &customization_block) : relation
        end
      end

      def belongs_to(name, options = {}, &customization_block)
        relates_to_1(name) do
          class_name = options[:class_name] || name.to_s.classify
          foreign_key = options[:foreign_key] || :"#{name}_id"
          relation = select_parent(class_name.to_s.constantize.set, :foreign_key => foreign_key)
          customization_block ? instance_exec(relation, &customization_block) : relation
        end
      end

      def create(attributes)
        set.insert(new(attributes))
      end      

      protected
      def instance_relation_definitions
        @instance_relation_definitions ||= inheritable_inject(:instance_relation_definitions) do |definitions, value|
          definitions.concat(value)
        end
      end
    end
    def self.included(a_module)
      a_module.extend ClassMethods
    end

    def initialize(initial_attributes={})
      super()
      @new = true
      @dirty = false
      @attribute_values = {}

      initialize_attribute_values(initial_attributes)
      initialize_instance_relations
    end

    def [](attribute)
      if attribute.is_a?(Relations::Set)
        raise "#attribute is only defined for Attribute's of this Tuple's #relation or its #relation itself" unless attribute == set
        self
      else
        attribute_values[attribute_for(attribute)]
      end
    end    

    def []=(attribute_or_symbol, new_value)
      attribute = attribute_for(attribute_or_symbol)
      old_value = attribute_values[attribute]
      if old_value != new_value
        attribute_values[attribute] = new_value
        update_subscription_node.call(attribute, old_value, new_value)
        @dirty = true unless new?
      end
      new_value
    end

    def has_attribute?(attribute)
      set.has_attribute?(attribute)
    end

    def attributes
      attributes = {}
      attribute_values.each do |attribute, value|
        attributes[attribute.name] = value
      end
      attributes          
    end

    def push
      Unison.origin.push(self)
      pushed
    end

    def pushed
      @new = false
      @dirty = false
      self
    end

    def new?
      @new
    end

    def dirty?
      @dirty
    end

    def set
      self.class.set
    end    

    def ==(other)
      return false unless other.is_a?(PrimitiveTuple)
      attribute_values == other.send(:attribute_values)
    end

    def <=>(other)
      self[:id] <=> other[:id]
    end

    def primitive?
      true
    end

    def compound?
      false
    end

    def select_children(target_relation, options={})
      target_relation.where(
        target_relation[child_foreign_key_from_options(options)].eq(self[:id])
      )
    end

    def select_child(target_relation, options={})
      target_relation.where(
        target_relation[child_foreign_key_from_options(options)].eq(self[:id])
      ).singleton
    end

    def select_parent(target_relation, options={})
      foreign_key = options[:foreign_key] || :"#{target_relation.name.to_s.singularize.underscore}_id"
      target_relation.where(target_relation[:id].eq(self[foreign_key])).singleton
    end

    def signal(attribute_or_symbol)
      Signal.new(self, attribute_for(attribute_or_symbol))
    end

    def inspect
      "<#{self.class.name} #attributes=#{attributes.inspect}>"
    end

    protected
    attr_reader :attribute_values

    def after_create
    end  

    def initialize_instance_relations
      instance_relation_definitions.each do |instance_relation_definition|
        instance_relation_definition.initialize_instance_relation(self)
      end
    end

    def initialize_attribute_values(initial_attributes)
      initial_attributes = default_attribute_values.merge(
        convert_symbol_keys_to_attributes(initial_attributes)
      )
      if initial_attributes[set[:id]] && !Unison.test_mode?
        raise "You can only assign the :id attribute in test mode"
      end
      initial_attributes[set[:id]] ||= Guid.new.to_s
      initial_attributes.each do |attribute, value|
        self[attribute] = value
      end
    end

    def has_many_through(target_relation, options)
      through_relation = self.send(options[:through])
      has_many_through_where_through_relation_has_foreign_key(target_relation, through_relation, options) \
      || has_many_through_where_target_relation_has_foreign_key(target_relation, through_relation, options) \
      || raise(ArgumentError, "Unable to construct a has_many\n#{target_relation.inspect}\nrelationship through\n#{through_relation.inspect}\nwith options #{options.inspect}")
    end

    def has_many_through_where_through_relation_has_foreign_key(target_relation, through_relation, options)
      foreign_key = options[:foreign_key] || :"#{target_relation.set.name.to_s.singularize.underscore}_id"
      if through_relation.has_attribute?(foreign_key)
        through_relation.
          join(target_relation).
          on(through_relation[foreign_key].eq(target_relation[:id])).
          project(target_relation)
      else
        nil
      end
    end

    def has_many_through_where_target_relation_has_foreign_key(target_relation, through_relation, options)
      foreign_key = options[:foreign_key] || :"#{through_relation.set.name.to_s.singularize.underscore}_id"
      if target_relation.has_attribute?(foreign_key)
        through_relation.
          join(target_relation).
            on(target_relation[foreign_key].eq(through_relation[:id])).
          project(target_relation)
      else
        nil
      end
    end    

    def convert_symbol_keys_to_attributes(attributes)
      attributes.inject({}) do |normalized_hash, pair|
        key, value = pair
        normalized_hash[set[key]] = value
        normalized_hash
      end
    end    

    def default_attribute_values
      self.class.default_attribute_values
    end

    def child_foreign_key_from_options(options)
      options[:foreign_key] || self.class.foreign_key_name
    end

    def instance_relation_definitions
      self.class.send(:instance_relation_definitions)
    end

    public
    class Base
      include PrimitiveTuple
    end
  end
end