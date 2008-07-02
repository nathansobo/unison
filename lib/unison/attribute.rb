module Unison
  class Attribute
    attr_reader :relation, :name

    def initialize(relation, name)
      @relation, @name = relation, name
    end

    def ==(other)
      return false unless other.instance_of?(Attribute)
      relation == other.relation && name == other.name
    end
  end
end