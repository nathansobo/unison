module Unison
  class Repository
    attr_reader :connection
    def initialize(connection)
      @connection = connection
    end

    def pull(relation)
      connection[relation.to_sql].map do |record|
        relation.tuple_class.new(record)
      end
    end
  end
end