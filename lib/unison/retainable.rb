module Unison
  module Retainable
    module ClassMethods
      def retains(*children)
        children_to_retain.concat(children)
      end

      protected
      def children_to_retain
        @children_to_retain ||= []
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end

    def retain(retainer)
      raise ArgumentError, "Object #{retainer.inspect} has already retained this Object" if retained_by?(retainer)
      retainers[retainer.object_id] = retainer
      if refcount == 1
        self.class.send(:children_to_retain).each do |retainable_name|
          send(retainable_name).retain(self)
        end
        after_first_retain
      end
    end

    def release(retainer)
      retainers.delete(retainer.object_id)
      destroy if refcount == 0
    end

    def refcount
      retainers.length
    end

    def retained_by?(potential_retainer)
      retainers[potential_retainer.object_id] ? true : false
    end

    protected
    def retainers
      @retainers ||= {}
    end

    def after_first_retain
      
    end

    def destroy

    end    
  end
end