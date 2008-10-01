module Unison
  class SyntheticField < Field
    def ==(other)
      other.is_a?(SyntheticField) && other.attribute == attribute
    end
  end
end