module Topics
  class Topic
    class << self
      def expose_to_client(relation_name)
        exposed_relations.push relation_name
      end

      def new_client_representation_for(tuple)
      end

      def exposed_relations
        @exposed_relations ||= []
      end
    end

    def initialize(session)
      
    end

    def to_hash
      return @hash if @hash
      exposed_relations.each do |relation_name|
        relation = room.send(relation_name)
        relation.on_insert do |inserted|
          client_representation = new_client_representation_for(inserted)
          client_representations[inserted.class.basename][inserted[:id].to_s] = client_representation
        end
        relation.on_remove do |removed|
          client_representations[inserted.class.basename].delete(inserted[:id].to_s)
        end
      end
    end

    protected
    def exposed_relations
      self.class.exposed_relations
    end
  end
end
