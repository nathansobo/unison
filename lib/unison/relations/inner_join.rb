module Unison
  module Relations
    class InnerJoin < CompositeRelation
      attr_reader :left_operand, :right_operand, :predicate
      retain :left_operand, :right_operand

      subscribe do
        left_operand.on_insert do |left_operand_tuple|
          right_operand.each do |right_operand_tuple|
            insert_if_predicate_matches CompositeTuple.new(left_operand_tuple, right_operand_tuple)
          end
        end
      end

      subscribe do
        right_operand.on_insert do |right_operand_tuple|
          left_operand.each do |left_operand_tuple|
            insert_if_predicate_matches CompositeTuple.new(left_operand_tuple, right_operand_tuple)
          end
        end
      end

      subscribe do
        left_operand.on_delete do |left_operand_tuple|
          delete_if_member_of_composite_tuple :left, left_operand_tuple
        end
      end

      subscribe do
        right_operand.on_delete do |right_operand_tuple|
          delete_if_member_of_composite_tuple :right, right_operand_tuple
        end
      end

      subscribe do
        left_operand.on_tuple_update do |left_operand_tuple, attribute, old_value, new_value|
          right_operand.tuples.each do |right_operand_tuple|
            composite_tuple = find_composite_tuple(left_operand_tuple, right_operand_tuple)
            if composite_tuple
              if predicate.eval(composite_tuple)
                tuple_update_subscription_node.call(composite_tuple, attribute, old_value, new_value)
              else
                delete(composite_tuple)
              end
            else
              insert_if_predicate_matches(CompositeTuple.new(left_operand_tuple, right_operand_tuple))
            end
          end
        end
      end

      subscribe do
        right_operand.on_tuple_update do |right_operand_tuple, attribute, old_value, new_value|
          left_operand.tuples.each do |left_operand_tuple|
            composite_tuple = find_composite_tuple(left_operand_tuple, right_operand_tuple)
            if composite_tuple
              if predicate.eval(composite_tuple)
                tuple_update_subscription_node.call(composite_tuple, attribute, old_value, new_value)
              else
                delete(composite_tuple)
              end
            else
              insert_if_predicate_matches(CompositeTuple.new(left_operand_tuple, right_operand_tuple))
            end
          end
        end
      end

      def initialize(left_operand, right_operand, predicate)
        super()
        @left_operand, @right_operand, @predicate = left_operand, right_operand, predicate
      end

      def operands
        [left_operand, right_operand]
      end

      def to_arel
        arel_join = left_operand.to_arel.join(right_operand.to_arel).on(predicate.to_arel)
        aliased_attributes = arel_join.attributes.map { |a| a.as("#{a.original_relation.name}__#{a.name}") }
        arel_join.project(*aliased_attributes)
      end

      def composite?
        true
      end

      def set
        raise NotImplementedError
      end

      def composed_sets
        left_operand.composed_sets + right_operand.composed_sets
      end

      def merge(composite_tuples)
        left_tuples = []
        right_tuples = []

        composite_tuples.each do |composite_tuple|
          left_tuples.push(composite_tuple.left)
          right_tuples.push(composite_tuple.right)
        end

        left_operand.merge(left_tuples)
        right_operand.merge(right_tuples)
      end

      def new_tuple(qualified_attributes)
        left_attributes, right_attributes = segregate_attributes(qualified_attributes)
        CompositeTuple.new(left_operand.new_tuple(left_attributes), right_operand.new_tuple(right_attributes))
      end

      def inspect
        "#{left_operand.inspect}.join(#{right_operand.inspect}).on(#{predicate.inspect})"
      end

      protected
      def segregate_attributes(qualified_attributes)
        left_set_names = left_operand.composed_sets.map { |set| set.name }
        right_set_names = right_operand.composed_sets.map { |set| set.name }

        left_attributes = {}
        right_attributes = {}

        qualified_attributes.each do |qualified_name, value|
          table_name, unqualified_name = qualified_name.to_s.split("__").map { |x| x.to_sym }
          if left_set_names.include?(table_name)
            name = left_operand.composite?? qualified_name : unqualified_name
            left_attributes[name] = value
          elsif right_set_names.include?(table_name)
            name = right_operand.composite?? qualified_name : unqualified_name
            right_attributes[name] = value
          else
            raise ArgumentError, "Invalid qualified table name: #{table_name.inspect}"
          end
        end

        [left_attributes, right_attributes]
      end

      def insert_if_predicate_matches(composite_tuple)
        insert(composite_tuple) if predicate.eval(composite_tuple)
      end

      def delete_if_member_of_composite_tuple(which_operand, tuple)
        tuples.each do |composite_tuple|
          if composite_tuple.send(which_operand) == tuple
            delete(composite_tuple)
          end
        end
      end

      def initial_read
        cartesian_product.select {|tuple| predicate.eval(tuple)}
      end

      def cartesian_product
        tuples = []
        left_operand.tuples.each do |tuple_1|
          right_operand.tuples.each do |tuple_2|
            tuples.push(CompositeTuple.new(tuple_1, tuple_2))
          end
        end
        tuples
      end

      def find_composite_tuple(left_operand_tuple, right_operand_tuple)
        tuples.find do |composite_tuple|
          composite_tuple.left == left_operand_tuple && composite_tuple.right == right_operand_tuple
        end
      end
    end
  end
end
