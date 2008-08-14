module Unison
  class PartialInnerJoin
    attr_reader :operand_1, :operand_2
    def initialize(operand_1, operand_2)
      @operand_1, @operand_2 = operand_1, operand_2
    end

    def on(predicate)
      Relations::InnerJoin.new(operand_1, operand_2, predicate)
    end
  end
end