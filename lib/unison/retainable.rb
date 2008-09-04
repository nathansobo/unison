module Unison
  module Retainable
    module ClassMethods
      def retains(*children)
        names_of_children_to_retain.concat(children)
      end

      def names_of_children_to_retain
        @names_of_children_to_retain ||= begin
          names = []
          current_class = superclass
          while current_class.respond_to?(:names_of_children_to_retain)
            names.concat(current_class.names_of_children_to_retain)
            current_class = current_class.superclass
          end
          names.uniq
        end
      end      
    end

    def self.included(mod)
      mod.extend ClassMethods
    end

    def retained_by(retainer)
      if retained_by?(retainer)
        raise(ArgumentError, "#{retainer.inspect}\nhas already retained\n#{inspect}")
      end
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
        destroy_subscriptions
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

    def subscribed_to?(subscription_node)
      subscriptions.any? do |subscription|
        subscription_node.include?(subscription)
      end
    end

    protected
    def retainers
      @retainers ||= {}
    end

    def after_first_retain
      
    end

    def after_last_release

    end

    def subscriptions
      @subscriptions ||= []
    end

    def retain_children
      children_to_retain.each do |child|
        child.retained_by(self)
      end
    end

    def destroy_subscriptions
      subscriptions.each do |subscription|
        subscription.destroy
      end
    end

    def release_children
      children_to_retain.each do |child|
        child.released_by(self)
      end
    end
    
    def children_to_retain
      self.class.send(:names_of_children_to_retain).inject([]) do |children, name|
        child = send(name)
        if child.is_a?(Retainable)
          children.push(child)
        else
          children.concat(child)
        end
        children
      end
    end
  end
end