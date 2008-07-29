module Unison
  module Relations
    class Projection < Relation
      attr_reader :operand, :attributes
      def initialize(operand, attributes)
        super()
        @operand, @attributes = operand, attributes
        @tuples = initial_read

        operand.on_insert do |created|
          projected = created[attributes]
          unless tuples.include?(projected)
            tuples.push(projected)
            trigger_on_insert(projected)
          end
        end
      end

      def read
        tuples
      end

      protected
      attr_reader :tuples
      def initial_read
        operand.read.map do |tuple|
          tuple[attributes]
        end.uniq
      end
    end
  end
end
