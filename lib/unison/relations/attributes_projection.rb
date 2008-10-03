module Unison
  module Relations
    class AttributesProjection < CompositeRelation
      attr_reader :operand, :projected_attributes

      retain :operand

      subscribe do
        operand.on_insert do |inserted_tuple|
          new_projected_tuple = create_projected_tuple_for(inserted_tuple)
          insert(new_projected_tuple) unless tuples.include?(new_projected_tuple)
        end
      end

      subscribe do
        operand.on_delete do |deleted_tuple|
          corresponding_projected_tuple = create_projected_tuple_for(deleted_tuple)
          delete(corresponding_projected_tuple) unless operand_contains_tuple_projecting_to?(corresponding_projected_tuple)
        end
      end

      subscribe do
        operand.on_tuple_update do |updated_tuple, attribute, old_value, new_value|
          if projected_attributes.include?(attribute)
            new_projected_tuple = create_projected_tuple_for(updated_tuple)
            prototypical_old_projected_tuple = new_projected_tuple.deep_clone
            prototypical_old_projected_tuple[attribute] = old_value
            old_projected_tuple = tuples.detect {|projected_tuple| projected_tuple == prototypical_old_projected_tuple}

            if operand_contains_tuple_projecting_to?(old_projected_tuple)
              if operand_contains_multiple_tuples_projecting_to?(new_projected_tuple)
                # noop
              else
                insert(new_projected_tuple)
              end
            else
              if operand_contains_multiple_tuples_projecting_to?(new_projected_tuple)
                delete(old_projected_tuple)
              else
                tuple_update(old_projected_tuple, attribute, old_value, new_value)
              end
            end
          end
        end
      end

      def initialize(operand, projected_attributes)
        super()
        @operand = operand
        @projected_attributes = translate_symbols_to_attributes(projected_attributes)
      end

      def attribute(name)
        raise ArgumentError, "Attribute with name #{name.inspect} is not defined on this Relation" unless has_attribute?(name)
        projected_attributes.detect do |attribute|
          attribute.name == name
        end
      end
      
      def has_attribute?(name)
        projected_attributes.any? do |attribute|
          attribute.name == name
        end
      end

      def tuple_class
        operand.tuple_class
      end

      protected
      def initial_read
        projected_tuples = []
        operand.tuples.each do |tuple|
          fields = projected_attributes.map do |attribute|
            tuple.field_for(attribute)
          end
          new_projected_tuple = ProjectedTuple.new(*fields)
          projected_tuples.push(new_projected_tuple) unless projected_tuples.include?(new_projected_tuple)
        end
        projected_tuples
      end

      def translate_symbols_to_attributes(attributes_or_symbols)
        attributes_or_symbols.map do |attribute_or_symbol|
          if attribute_or_symbol.is_a?(Attributes::Attribute)
            attribute_or_symbol
          else
            operand.attribute(attribute_or_symbol)
          end
        end
      end

      def create_projected_tuple_for(tuple)
        fields = projected_attributes.map {|attribute| tuple.field_for(attribute) }
        ProjectedTuple.new(*fields)
      end

      def operand_contains_tuple_projecting_to?(projected_tuple)
        operand.tuples.any? do |base_tuple|
          create_projected_tuple_for(base_tuple) == projected_tuple
        end
      end

      def operand_contains_multiple_tuples_projecting_to?(projected_tuple)
        operand.tuples.select do |base_tuple|
          create_projected_tuple_for(base_tuple) == projected_tuple
        end.size > 1
      end

      def tuple_update(tuple, attribute, old_value, new_value)
        tuple[attribute] = new_value
        tuple_update_subscription_node.call(tuple, attribute, old_value, new_value)
      end
    end
  end
end
