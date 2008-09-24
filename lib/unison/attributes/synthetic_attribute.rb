module Unison
  module Attributes
    class SyntheticAttribute < Attribute
      attr_reader :set, :name, :definition

      def initialize(set, name, &definition)
        @set, @name, @definition = set, name, definition
      end

      def ==(other)
        return false unless other.instance_of?(SyntheticAttribute)
        set.equal?(other.set) && name == other.name && definition == other.definition
      end

      def to_arel
        set.to_arel[name]
      end
    end
  end
end