module Unison
  module Tuples
    class ProjectedTuple < Tuple
      attr_reader :fields
      def initialize(*fields)
        @fields = fields.map {|field| field.dup }
      end

      def [](attribute_or_symbol)
        field_for(attribute_or_symbol).value
      end

      def []=(attribute_or_symbol, value)
        field_for(attribute_or_symbol).set_value(value)
      end

      def ==(other)
        raise ArgumentError, "Argument to == must be an instance of ProjectedTuple" unless other.instance_of?(ProjectedTuple)
        fields == other.fields
      end

      def deep_clone
        ProjectedTuple.new(*(fields.map {|field| field.dup }))  
      end

      protected
      def field_for(attribute_or_symbol)
        name = attribute_or_symbol.instance_of?(Symbol) ? attribute_or_symbol : attribute_or_symbol.name
        fields.each do |field|
          return field if field.attribute.name == name
        end
        raise ArgumentError, "Attribute #{attribute_or_symbol} must be the the name of a Field in the ProjectedTuple"
      end
    end
  end
end

