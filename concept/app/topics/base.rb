module Topics
  class Base
    class << self
      def expose_to_client(relation_name)
        relation = root_object.send(relation_name)
        relation.on_insert do |inserted|
          client_representation = new_client_representation_for(inserted)
          client_representations[inserted.class.basename][inserted[:id].to_s] = client_representation
        end
        relation.on_remove do |removed|
          client_representations[inserted.class.basename].delete(inserted[:id].to_s)
        end
      end

      def new_client_representation_for(tuple)
#        tuple.on_update
        
      end

    end
  end
end