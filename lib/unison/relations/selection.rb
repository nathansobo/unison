module Unison
  module Relations
    class Selection < Relation
      attr_reader :operand, :predicate

      def initialize(operand, predicate)
        super()
        @operand, @predicate = operand, predicate
        @tuples = initial_read

        predicate.on_update do
          new_tuples = initial_read
          deleted_tuples = tuples - new_tuples
          inserted_tuples = new_tuples - tuples
          tuples.clear
          tuples.concat initial_read
          deleted_tuples.each do |deleted_tuple|
            trigger_on_delete(deleted_tuple)
          end
          inserted_tuples.each do |inserted_tuple|
            trigger_on_insert(inserted_tuple)
          end
        end

        operand.on_insert do |created|
          if predicate.eval(created)
            tuples.push(created)
            trigger_on_insert(created)
          end
        end

        operand.on_delete do |deleted|
          if predicate.eval(deleted)
            tuples.delete(deleted)
            trigger_on_delete(deleted)
          end
        end
      end

      def ==(other)
        return false unless other.instance_of?(Selection)
        operand == other.operand && predicate == other.predicate
      end

      def read
        tuples
      end

      def size
        read.size
      end

      protected
      attr_reader :tuples

      def initial_read
        operand.read.select do |tuple|
          predicate.eval(tuple)
        end
      end

    end
  end
end