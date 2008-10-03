module Unison
  class Repository
    attr_reader :connection
    def initialize(connection)
      @connection = connection
    end

    def fetch(relation)
      raise NotImplementedError, "You cannot fetch Relations that contain CompositeTuples" if relation.is_a?(Relations::InnerJoin)
      connection[relation.to_sql].map do |record|
        relation.tuple_class.new(record).pushed
      end
    end

    def push(relation_or_tuple)
      if relation_or_tuple.is_a?(Relations::InnerJoin) || relation_or_tuple.is_a?(CompositeTuple)
        raise NotImplementedError, "You cannot push CompositeTuples or Relations that contain CompositeTuples"
      end
      table = connection[relation_or_tuple.set.name]
      if relation_or_tuple.respond_to?(:tuples)
        relation_or_tuple.tuples.each do |tuple|
          push_tuple(table, tuple)
        end
      else
        push_tuple(table, relation_or_tuple)
      end
    end

    protected
    def push_tuple(table, tuple)
      if tuple.new?
        table << tuple.persistent_hash_representation
      elsif tuple.dirty?
        update_tuple(table, tuple)
      end
      tuple.pushed
    end

    def update_tuple(table, tuple)
      table.filter("id=?", tuple.id).update(tuple.persistent_hash_representation)
    end
  end
end