module Unison
  module Domains
    class Domain
      include Unison
      include Retainable      
      class << self
        def relates_to_many(name, &definition)
          instance_relation_definitions_on_self.push(InstanceRelationDefinition.new(name, definition, caller, false))
          attr_reader "#{name}_relation"
          alias_method name, "#{name}_relation"
        end

        def relates_to_one(name, &definition)
          instance_relation_definitions_on_self.push(InstanceRelationDefinition.new(name, definition, caller, true))
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
        def instance_relation_definitions
          responders_in_inheritance_chain(:instance_relation_definitions_on_self).inject([]) do |definitions, klass|
            definitions.concat(klass.send(:instance_relation_definitions_on_self))
          end
        end

        def instance_relation_definitions_on_self
          @instance_relation_definitions_on_self ||= []
        end

        def synthetic_attribute_definitions
          @synthetic_attribute_definitions ||= {}
        end
      end

      def initialize
        initialize_instance_relations
      end      

      protected
      def initialize_instance_relations
        instance_relation_definitions.each do |instance_relation_definition|
          instance_relation_definition.initialize_instance_relation(self)
        end
      end

      def instance_relation_definitions
        self.class.send(:instance_relation_definitions)
      end
    end
  end
end
