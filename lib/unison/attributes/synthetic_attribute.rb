module Unison
  module Attributes
    class SyntheticAttribute < Attribute
      attr_reader :definition

      def initialize(set, name, &definition)
        super(set, name)
        @definition = definition
      end

      def ==(other)
        return false unless other.instance_of?(SyntheticAttribute)
        set.equal?(other.set) && name == other.name && definition == other.definition
      end

      def create_field(tuple)
        SyntheticField.new(tuple, self)
      end
    end
  end
end