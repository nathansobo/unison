module Unison
  class SyntheticField < Field
    def initialize(tuple, attribute)
      unless attribute.instance_of?(Attributes::SyntheticAttribute)
        raise ArgumentError, "SyntheticFields can only be constructed for SyntheticAttributes"
      end
      super
    end

    def signal
      @signal ||= tuple.instance_eval(&attribute.definition)
    end

    def value
      signal.value
    end

    def ==(other)
      other.is_a?(SyntheticField) && other.attribute == attribute
    end
  end
end