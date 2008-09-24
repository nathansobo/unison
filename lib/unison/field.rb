module Unison
  class Field
    attr_reader :attribute
    attr_reader :value
    
    def initialize(attribute)
      @attribute = attribute
      @dirty = false
    end
    
    def set_value(new_value)
      old_value = value
      converted_new_value = attribute.convert(new_value)
      if old_value != converted_new_value
        @value = converted_new_value
        yield(attribute, old_value, converted_new_value) if block_given?
        @dirty = true
      end
      converted_new_value
    end

    def dirty?
      @dirty ? true : false
    end

    def pushed
      @dirty = false
    end

    def ==(other)
      other.is_a?(Field) && other.attribute == attribute && other.value == value
    end
  end
end