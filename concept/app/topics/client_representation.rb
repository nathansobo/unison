module Topics
  class ClientRepresentation
    attr_reader :model
    def initialize(model)
      @model = model
    end

    def ==(other)
      model == other.model
    end
  end
end
