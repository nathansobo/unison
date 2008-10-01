module Unison
  class Field
    attr_reader :tuple, :attribute

    def initialize(tuple, attribute)
      @tuple, @attribute = tuple, attribute
    end
  end
end