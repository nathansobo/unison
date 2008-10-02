module Unison
  module Tuples
    class ProjectedTuple < Tuple
      attr_reader :fields
      def initialize(*fields)
        @fields = fields
      end

      def [](attribute_or_symbol)
        name = attribute_or_symbol.instance_of?(Symbol) ? attribute_or_symbol : attribute_or_symbol.name
        fields.each do |field|
          return field.value if field.attribute.name == name
        end
        raise ArgumentError, "Attribute #{attribute_or_symbol} must be the the name of a Field in the ProjectedTuple"
      end

      def ==(other)
        raise ArgumentError, "Argument to == must be an instance of ProjectedTuple" unless other.instance_of?(ProjectedTuple)
        fields == other.fields
      end
    end
  end
end

