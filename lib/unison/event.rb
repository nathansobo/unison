module Unison
  class Event
    attr_reader :relation, :type, :object
    def initialize(relation, type, object)
      @relation, @type, @object = relation, type, object
    end
  end
end