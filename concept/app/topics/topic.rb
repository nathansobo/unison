module Topics
  class Topic
    class << self
      def expose_to_client(relation_name)
        exposed_relations.push relation_name
      end

      def exposed_relations
        @exposed_relations ||= []
      end
    end

    def initialize(session)
      
    end

    def to_hash
      return hash if hash
      @hash = {}
      exposed_relations.each do |relation_name|
        relation = relation_from_name(relation_name)
        class_name = nil
        relation.tuples.each do |tuple|
          class_name ||= tuple.class.basename
          hash[class_name] ||= {}
          hash[class_name][tuple[:id].to_s] = new_client_representation_for(tuple, class_name)
        end
        relation.on_insert do |inserted|
          class_name ||= inserted.class.basename
          client_representation = new_client_representation_for(inserted, class_name)
          hash[class_name] ||= {}
          hash[class_name][inserted[:id].to_s] = client_representation
        end
        relation.on_delete do |removed|
          class_name ||= inserted.class.basename
          hash[class_name] ||= {}
          hash[class_name].delete(removed[:id].to_s)
        end
      end
      hash
    end

    protected
    attr_reader :hash
    def exposed_relations
      self.class.exposed_relations
    end

    def relation_from_name(relation_name)
      if relation_name == :self
        room.relation.where(room.relation[:id].eq(room[:id]))
      else
        room.send(relation_name)
      end
    end

    def new_client_representation_for(tuple, class_name)
      self.class.const_get(class_name).new(tuple)
    end
  end
end
