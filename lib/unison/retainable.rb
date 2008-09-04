module Unison
  module Retainable
    module ClassMethods
      def retains(*children)
        names_of_children_to_retain.concat(children)
      end

      protected
      def names_of_children_to_retain
        @names_of_children_to_retain ||= []
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end

    def retained_by(retainer)
      raise ArgumentError, "Object #{retainer.inspect} has already retained this Object" if retained_by?(retainer)
      retainers[retainer.object_id] = retainer
      if refcount == 1
        retain_children
        after_first_retain
      end
      self
    end

    def released_by(retainer)
      retainers.delete(retainer.object_id)
      if refcount == 0
        release_children
        after_last_release
      end
    end

    def refcount
      retainers.length
    end

    def retained?
      !retainers.empty?
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

    def after_last_release

    end

    def retain_children
      children_to_retain.each do |child|
        child.retained_by(self)
      end
    end

    def release_children
      children_to_retain.each do |child|
        child.released_by(self)
      end
    end
    
    def children_to_retain
      self.class.send(:names_of_children_to_retain).map do |name|
        send(name)
      end
    end
  end
end