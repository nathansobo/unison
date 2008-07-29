module Unison
  module Relations
    class Projection < Relation
      attr_reader :operand, :attributes
      def initialize(operand, attributes)
        super()
        @operand, @attributes = operand, attributes
        @tuples = initial_read

        operand.on_insert do |created|
          restricted = created[attributes]
          unless tuples.include?(restricted)
            tuples.push(restricted)
            trigger_on_insert(restricted)
          end
        end

        operand.on_delete do |deleted|
          restricted = deleted[attributes]
          unless initial_read.include?(restricted)
            tuples.delete(restricted)
            trigger_on_delete(restricted)
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
