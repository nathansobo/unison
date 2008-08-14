module Unison
  class Repository
    attr_reader :connection
    def initialize(connection)
      @connection = connection
    end

    def fetch(relation)
      raise NotImplementedError, "You cannot fetch Relations that contain CompoundTuples" if relation.is_a?(Relations::InnerJoin)
      connection[relation.to_sql].map do |record|
        relation.tuple_class.new(record)
      end
    end

    def push(relation)
      raise "You cannot push Relations that contain CompoundTuples" if relation.is_a?(Relations::InnerJoin)
      table = connection[relation.set.name]
      relation.each do |tuple|
        table << tuple.attributes
        tuple.persisted
      end
    end
  end
end