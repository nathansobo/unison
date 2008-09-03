module Unison
  class Repository
    attr_reader :connection
    def initialize(connection)
      @connection = connection
    end

    def fetch(relation)
      raise NotImplementedError, "You cannot fetch Relations that contain CompositeTuples" if relation.is_a?(Relations::InnerJoin)
      connection[relation.to_sql].map do |record|
        relation.tuple_class.new(record).persisted
      end
    end

    def push(relation)
      raise "You cannot push Relations that contain CompositeTuples" if relation.is_a?(Relations::InnerJoin)
      table = connection[relation.set.name]
      relation.each do |tuple|
        if tuple.new?
          table << tuple.attributes
        elsif tuple.dirty?
          table.filter("id=?", tuple.id).update(tuple.attributes)
        end
        tuple.persisted
      end
    end
  end
end