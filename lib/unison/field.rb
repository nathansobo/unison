module Unison
  class Field
    attr_reader :attribute
    attr_accessor :value
    
    def initialize(attribute)
      @attribute = attribute
    end

    def ==(other)
      other.is_a?(Field) && other.attribute == attribute && other.value == value
    end
  end
end