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
      end

      retain :exposed_objects
      attribute :hash_representation, :object

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
        hash = {}
        exposed_objects.each do |relation|
          tuple_class_name = relation.tuple_class.basename
          relation.tuples.each do |tuple|
            hash[tuple_class_name] ||= {}
            hash[tuple_class_name][tuple.id] = tuple.attributes.stringify_keys
          end
        end
        hash
      end

      def to_hash
        hash_representation
      end

      protected
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
