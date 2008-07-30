module Unison
  module Retainable
    def retain(retainer)
      raise ArgumentError, "Object #{retainer.inspect} has already retained this Object" if retained_by?(retainer)
      retainers[retainer.object_id] = retainer
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

    def destroy

    end    
  end
end