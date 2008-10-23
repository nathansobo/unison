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
          @set ||= single_set_inheritance_subclass?? superclass.set : member_of(create_default_set)
        end
        attr_writer :set

        def member_of(set)
          @set = set.retain_with(self)
          set.tuple_class = self
          set
        end

        def attribute(name, type, options={}, &transform)
          set.add_primitive_attribute(name, type, options, &transform)
        end

        def attribute_reader(name, type, options={}, &transform)
          attribute = self.attribute(name, type, options, &transform)
          define_method(name) do
            self[attribute]
          end
          alias_method "#{name}?", name if type == :boolean
          attribute
        end

        def attribute_writer(name, type, options={}, &transform)
          attribute = self.attribute(name, type, options, &transform)
          define_method("#{name}=") do |value|
            self[attribute] = value
          end
          attribute
        end

        def synthetic_attribute(name, &definition)
          synthetic_attribute = set.add_synthetic_attribute(name, &definition)
          define_method(name) do
            self[synthetic_attribute]
          end
          synthetic_attribute
        end

        def attribute_accessor(name, type, options={}, &transform)
          attribute_reader(name, type, options, &transform)
          attribute_writer(name, type, options, &transform)
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

        def where(predicate)
          set.where(predicate)
        end

        def order_by(*order_by_attributes)
          set.order_by(*order_by_attributes)
        end

        def project(*attributes_or_set)
          set.project(*attributes_or_set)
        end

        def find(id_or_predicate)
          set.find(id_or_predicate)
        end

        def find_or_pull(id_or_predicate)
          set.find_or_pull(id_or_predicate)
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

        def memory_fixtures(fixtures)
          set.memory_fixtures(fixtures)
        end

        def load_memory_fixtures
          set.load_memory_fixtures
        end

        def database_fixtures(fixtures)
          set.database_fixtures(fixtures)
        end

        def load_database_fixtures
          set.load_database_fixtures
        end

        protected
        def single_set_inheritance_subclass?
          superclass != PrimitiveTuple && superclass != Topic
        end

        def create_default_set
          Relations::Set.new(basename.underscore.pluralize.to_sym)
        end
        
        def relation_definitions
          responders_in_inheritance_chain(:relation_definitions_on_self).inject([]) do |definitions, klass|
            definitions.concat(klass.send(:relation_definitions_on_self))
          end
        end

        def relation_definitions_on_self
          @relation_definitions_on_self ||= []
        end
      end

      attr_reader :fields_hash

      def initialize(initial_attributes={})
        @new = true
        super()
        @fields_hash = create_fields_hash
        initialize_primitive_field_values(initial_attributes)
        initialize_relations
      end

      def [](attribute_or_symbol)
        if attribute_or_symbol.is_a?(Relations::Set)
          raise "#attribute is only defined for Attributes of this Tuple's #relation or its #relation itself" unless attribute_or_symbol == set
          self
        else
          attribute = attribute_for(attribute_or_symbol)
          value = fields_hash[attribute].value
          (attribute.respond_to?(:transform) && attribute.transform) ? instance_exec(value, &attribute.transform) : value
        end
      end

      def []=(attribute_or_symbol, new_value)
        field_for(attribute_or_symbol).set_value(new_value) do |attribute, old_value, converted_new_value|
          update_subscription_node.call(attribute, old_value, converted_new_value)
          set.notify_tuple_update_subscribers(self, attribute, old_value, converted_new_value)
        end
      end

      def has_attribute?(attribute)
        set.has_attribute?(attribute)
      end

      def has_synthetic_attribute?(name)
        set.has_synthetic_attribute?(name)
      end

      def persistent_hash_representation
        persistent_hash_representation = {}
        set.primitive_attributes.each do |attribute|
          persistent_hash_representation[attribute.name] = self[attribute]
        end
        persistent_hash_representation
      end

      def hash_representation
        returning({}) do |hash_representation|
          fields_hash.each do |attribute, field|
            hash_representation[attribute.name] = field.value          
          end
        end
      end

      def fields
        fields_hash.values
      end

      def primitive_fields
        fields.select {|field| field.instance_of?(PrimitiveField)}
      end

      def synthetic_fields
        fields.select {|field| field.instance_of?(SyntheticField)}
      end

      def field_for(attribute_or_symbol)
        fields_hash[attribute_for(attribute_or_symbol)]
      end

      def push
        Unison.origin.push(self)
        pushed
      end

      def pushed
        @new = false
        primitive_fields.each do |field|
          field.pushed
        end
        self
      end

      def delete
        set.delete(self)
      end

      def new?
        @new
      end

      def dirty?
        primitive_fields.any? {|field| field.dirty?}
      end

      def set
        self.class.set
      end

      def ==(other)
        return false unless other.is_a?(PrimitiveTuple)
        fields == other.send(:fields)
      end

      def <=>(other)
        self[:id] <=> other[:id]
      end

      def primitive?
        true
      end

      def composite?
        false
      end

      def signal(attribute_or_symbol, &block)
        signal =
          if has_attribute?(attribute_or_symbol)
            field_for(attribute_or_symbol).signal
          elsif has_singleton_relation?(attribute_or_symbol)
            Signals::SingletonRelationSignal.new(send(attribute_or_symbol))
          else
            raise ArgumentError, "There is no attribute or relation #{attribute_or_symbol.inspect} on #{self.inspect}"
          end
        block ? signal.signal(&block) : signal
      end

      def inspect
        "<#{self.class.name} #attributes=#{persistent_hash_representation.inspect}>"
      end

      protected
      def after_create
      end

      def after_merge
      end

      def create_fields_hash
        returning({}) do |fields_hash|
          set.attributes.values.each do |attribute|
            fields_hash[attribute] = attribute.create_field(self)
          end
        end
      end

      def initialize_primitive_field_values(initial_attributes)
        initial_attributes = convert_symbol_keys_to_attributes(initial_attributes)
        if initial_attributes[set[:id]] && !Unison.test_mode?
          raise "You can only assign the :id attribute in test mode"
        end
        initial_attributes.each do |attribute, attribute_value|
          fields_hash[attribute].set_value(attribute_value)
        end
        primitive_fields.each do |field|
          field.set_default_value unless initial_attributes.has_key?(field.attribute)
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

      def convert_symbol_keys_to_attributes(attributes)
        attributes.inject({}) do |normalized_hash, pair|
          key, value = pair
          normalized_hash[set[key]] = value
          normalized_hash
        end
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