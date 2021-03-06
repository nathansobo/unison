module Unison
  module Retainable
    module ClassMethods
      def retain(*children)
        names_of_children_to_retain_on_self.concat(children)
      end

      def subscribe(&subscription_definition)
        subscription_definitions_on_self.push(subscription_definition)
      end

      def subscription_definitions
        responders_in_inheritance_chain(:subscription_definitions_on_self).inject([]) do |definitions, klass|
          definitions.concat(klass.send(:subscription_definitions_on_self))
        end
      end

      def names_of_children_to_retain
        responders_in_inheritance_chain(:names_of_children_to_retain_on_self).inject([]) do |names, klass|
          names.concat(klass.send(:names_of_children_to_retain_on_self))
        end.uniq
      end

      def responders_in_inheritance_chain(method_name)
        chain = []
        current_class = self
        while current_class.respond_to?(method_name)
          chain.unshift(current_class)
          current_class = current_class.superclass
        end
        chain
      end

      protected
      def subscription_definitions_on_self
        @subscription_definitions_on_self ||= []
      end

      def names_of_children_to_retain_on_self
        @names_of_children_to_retain_on_self ||= []
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end

    def retain_with(retainer)
      if retained_by?(retainer)
        raise(ArgumentError, "#{retainer.inspect}\nhas already retained\n#{inspect}")
      end
      retainers[retainer.object_id] = retainer
      if refcount == 1
        retain_children
        subscribe_to_children
        after_first_retain
      end
      self
    end

    def release_from(retainer)
      deleted = retainers.delete(retainer.object_id)
      if deleted && !has_ancestral_root_retainer_other_than?(self)
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

    def has_ancestral_root_retainer_other_than?(origin_object, objects_seen_so_far=[])
      origin_object_id = origin_object.object_id
      object_ids_seen_so_far = objects_seen_so_far.map {|object| object.object_id}
      retainers.each do |retainer_object_id, retainer|
        if retainer_object_id != origin_object_id && !object_ids_seen_so_far.include?(retainer_object_id)
          if retainer.is_a?(Retainable)
            if retainer.retainers.empty?
              return true
            else
              return true if retainer.has_ancestral_root_retainer_other_than?(origin_object, objects_seen_so_far + [self])
            end
          else
            return true
          end
        end
      end
      false
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

    def subscribe_to_children
      subscription_definitions.each do |subscription_definition|
        subscriptions.push(*[instance_eval(&subscription_definition)].flatten.compact)
      end
    end

    def retain_children
      children_to_retain.each do |child|
        child.retain_with(self)
      end
    end

    def destroy_subscriptions
      subscriptions.each do |subscription|
        subscription.destroy
      end
    end

    def release_children
      children_to_retain.each do |child|
        child.release_from(self)
      end
    end

    def children_to_retain
      self.class.send(:names_of_children_to_retain).inject([]) do |children, name|
        child = send(name)
        case child
        when Retainable
          children.push(child)
        when Hash
          children.concat(child.values)
        else
          children.concat(child)
        end
        children
      end
    end

    def subscription_definitions
      self.class.subscription_definitions
    end
  end
end