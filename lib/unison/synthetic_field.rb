module Unison
  class SyntheticField < Field
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