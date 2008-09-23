module Unison
  module Tuples
    class PrimitiveTuple < Tuple
      include Enumerable

      class << self
        def new(attrs={})
          instance = polymorphic_allocate(attrs)
          instance.send(:initialize, attrs)
          instance
        end

        def polymorphic_allocate(attrs)
          allocate
        end

        def set
          @set || (superclass.respond_to?(:set) ? superclass.set : nil)
        end
        attr_writer :set

        def member_of(set)
          @set = set.retain_with(self)
          set.tuple_class = self
        end

        def default_attribute_values
          responders = responders_in_inheritance_chain(:default_attribute_values_on_self)
          responders.inject({self[:id] => lambda {Guid.new.to_s}}) do |defaults, klass|
            defaults.merge(klass.default_attribute_values_on_self)
          end
        end

        def default_attribute_values_on_self
          @default_attribute_values_on_self ||= {}
        end

        def attribute(name, type, options={})
          attribute = set.has_attribute(name, type)
          if options.has_key?(:default)
            default_attribute_values_on_self[attribute] = options[:default]
          end
          attribute
        end

        def attribute_reader(name, type, options={})
          attribute = self.attribute(name, type, options)
          define_method(name) do
            self[attribute]
          end
          alias_method "#{name}?", name if type == :boolean
        end

        def attribute_writer(name, type, options={})
          attribute = self.attribute(name, type, options)
          define_method("#{name}=") do |value|
            self[attribute] = value
          end
        end

        def synthetic_attribute(name, &definition)
          synthetic_attribute_definitions[name] = definition
          define_method(name) do
            synthetic_attribute_signals[name].value
          end
        end

        def attribute_accessor(name, type, options={})
          attribute_reader(name, type, options)
          attribute_writer(name, type, options)
        end

        def has_many(name, options={}, &customization_block)
          relates_to_many(name) do
            customize_relation(
              (options[:through] ? Relations::HasManyThrough : Relations::HasMany).new(self, name, options),
              &customization_block
            )
          end
        end

        def has_one(name, options={}, &customization_block)
          relates_to_one(name) do
            customize_relation(Relations::HasOne.new(self, name, options), &customization_block)
          end
        end

        def belongs_to(name, options = {}, &customization_block)
          relates_to_one(name) do
            customize_relation(Relations::BelongsTo.new(self, name, options), &customization_block)
          end
        end

        def create(attributes)
          set.insert(new(attributes))
        end

        def relates_to_many(name, &definition)
          relation_definitions_on_self.push(RelationDefinition.new(name, definition, caller, false))
          attr_reader "#{name}_relation"
          alias_method name, "#{name}_relation"
        end

        def relates_to_one(name, &definition)
          relation_definitions_on_self.push(RelationDefinition.new(name, definition, caller, true))
          relation_method_name = "#{name}_relation"
          attr_reader relation_method_name
          method_definition_line = __LINE__ + 1
          method_definition = %{
            def #{name}
              @#{relation_method_name}.nil?? nil : @#{relation_method_name}
            end
          }
          class_eval(method_definition, __FILE__, method_definition_line)
        end

        protected
        def relation_definitions
          responders_in_inheritance_chain(:relation_definitions_on_self).inject([]) do |definitions, klass|
            definitions.concat(klass.send(:relation_definitions_on_self))
          end
        end

        def relation_definitions_on_self
          @relation_definitions_on_self ||= []
        end

        def synthetic_attribute_definitions
          @synthetic_attribute_definitions ||= {}
        end        
      end

      def initialize(initial_attributes={})
        @new = true
        @dirty = false
        @attribute_values = {}
        @synthetic_attribute_signals = {}
        super()
        initialize_attribute_values(initial_attributes)
        initialize_relations
        initialize_synthetic_attribute_signals
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
        converted_new_value = attribute.convert(new_value)
        if old_value != converted_new_value
          attribute_values[attribute] = converted_new_value
          update_subscription_node.call(attribute, old_value, converted_new_value)
          @dirty = true unless new?
        end
        converted_new_value
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

      def delete
        set.delete(self)
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

      def signal(attribute_or_symbol, &block)
        signal =
          if has_synthetic_attribute?(attribute_or_symbol)
            synthetic_attribute_signals[attribute_or_symbol]
          elsif has_singleton_relation?(attribute_or_symbol)
            Signals::SingletonRelationSignal.new(send(attribute_or_symbol))
          elsif has_attribute?(attribute_or_symbol)
            Signals::AttributeSignal.new(self, attribute_for(attribute_or_symbol))
          else
            raise ArgumentError, "There is no attribute or relation #{attribute_or_symbol.inspect} on #{self.inspect}"
          end
        block ? signal.signal(&block) : signal
      end

      def inspect
        "<#{self.class.name} #attributes=#{attributes.inspect}>"
      end

      protected
      attr_reader :attribute_values, :synthetic_attribute_signals

      def after_create
      end

      def initialize_attribute_values(initial_attributes)
        initial_attributes = convert_symbol_keys_to_attributes(initial_attributes)
        if initial_attributes[set[:id]] && !Unison.test_mode?
          raise "You can only assign the :id attribute in test mode"
        end

        initial_attributes.each do |attribute, attribute_value|
          self[attribute] = attribute_value
        end

        assign_default_attribute_values(initial_attributes)
      end

      def assign_default_attribute_values(initial_attributes)
        default_attribute_values.each do |attribute, default_value|
          next if initial_attributes.has_key?(attribute)
          self[attribute] = default_value.is_a?(Proc)? instance_eval(&default_value) : default_value
        end
      end

      def initialize_synthetic_attribute_signals
        synthetic_attribute_definitions.each do |name, definition|
          synthetic_attribute_signals[name] = instance_eval(&definition)
        end
      end

      def initialize_relations
        relation_definitions.each do |relation_definition|
          relation_definition.initialize_relation(self)
        end
      end

      def relation_definitions
        self.class.send(:relation_definitions)
      end

      def synthetic_attribute_definitions
        self.class.send(:synthetic_attribute_definitions)
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

      def has_synthetic_attribute?(name)
        synthetic_attribute_definitions.has_key?(name)
      end

      def has_singleton_relation?(name)
        relation_definitions.any? do |definition|
          definition.name == name &&
            self.send(name).is_a?(Relations::SingletonRelation)
        end
      end

      def customize_relation(relation, &customization_block)
        customization_block ? instance_exec(relation, &customization_block) : relation
      end
    end    
  end
end