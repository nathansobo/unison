module Unison
  module Relations
    class Projection < Relation
      attr_reader :operand, :attributes
      def initialize(operand, attributes)
        super()
        @operand, @attributes = operand, attributes

        operand.on_insert do |created|
          trigger_on_insert(created[attributes])
        end
      end

      def read
        operand.read.map do |tuple|
          tuple[attributes]
        end.uniq
      end
    end
  end
end
