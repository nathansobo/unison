module Unison
  module Tuples
    class Topic < PrimitiveTuple
      class << self
        attr_reader :subject_method_name
        def expose(*names)
          exposed_method_names.concat(names)
        end

        def subject(name)
          @subject_method_name = name
        end

        protected
        def exposed_method_names
          @exposed_method_names ||= []
        end

        def inherited(subclass)
          super
          subclass.attribute(:hash_representation, :object)
        end
      end

      retain :exposed_objects

      subscribe do
        exposed_objects.map do |exposed_relation|
          [
            exposed_relation.on_insert do |tuple|
              add_to_hash_representation(tuple)
              attribute_mutated(:hash_representation)
            end,
            exposed_relation.on_delete do |tuple|
              remove_from_hash_representation(tuple)
              attribute_mutated(:hash_representation)
            end,
            exposed_relation.on_tuple_update do |tuple, attribute, old_value, new_value|
              update_in_hash_representation(tuple, attribute, new_value)
              attribute_mutated(:hash_representation)
            end
          ]
        end.flatten
      end

      def exposed_objects
        self.class.send(:exposed_method_names).map do |name|
          self.send(name)
        end
      end

      def subject
        subject_method_name = self.class.subject_method_name
        raise(NoSubjectError, "You must define a .subject on #{self.class}") unless subject_method_name
        send(subject_method_name)
      end

      def hash_representation
        self[:hash_representation] || create_hash_representation
      end

      def to_hash
        hash_representation
      end

      protected
      def after_first_retain
        self[:hash_representation] = create_hash_representation
      end

      def after_last_release
        self[:hash_representation] = nil
      end

      def create_hash_representation
        hash = {}
        exposed_objects.each do |relation|
          tuple_class_name = relation.tuple_class.basename
          relation.tuples.each do |tuple|
            add_to_hash_representation(tuple, hash, tuple_class_name)
          end
        end
        hash
      end

      def add_to_hash_representation(tuple, hash_representation=self.hash_representation, tuple_class_name=tuple.class.basename)
        hash_representation[tuple_class_name] ||= {}
        hash_representation[tuple_class_name][tuple.id] = tuple.attributes.stringify_keys
      end

      def remove_from_hash_representation(tuple)
        hash_representation[tuple.class.basename].delete(tuple.id)
      end

      def update_in_hash_representation(tuple, attribute, new_value)
        hash_representation[tuple.class.basename][tuple.id][attribute.name.to_s] = new_value
      end

      def attribute_mutated(attribute_or_name)
        attribute = attribute_for(attribute_or_name)
        update_subscription_node.call(attribute, self[attribute], self[attribute])
      end      

      def method_missing(method_name, *args, &block)
        subject.send(method_name, *args, &block)
      rescue NoMethodError => e
        e.message.replace("undefined method `#{method_name}' for #{inspect}")
        raise e
      end

      public
      class NoSubjectError < RuntimeError
      end
    end
  end
end
