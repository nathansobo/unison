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

          subclass.attribute_reader(:hash_representation, :object) do |value|
            value || create_hash_representation
          end

          subclass.synthetic_attribute(:json_representation) do
            signal(:hash_representation).signal(:to_json)
          end
        end
      end

      retain :exposed_objects

      subscribe do
        exposed_relations.map do |relation|
          subscribe_to_relation(relation)
        end.flatten
      end

      subscribe do
        exposed_signals.map do |signal|
          subscribe_to_signal(signal)
        end
      end

      def exposed_relations
        exposed_objects.select {|object| object.is_a?(Relations::Relation)}
      end

      def exposed_signals
        exposed_objects.select {|object| object.is_a?(Signals::Signal)}
      end

      def exposed_objects
        exposed_method_names.map do |name|
          self.send(name)
        end
      end

      def exposed_method_names
        self.class.send(:exposed_method_names)
      end

      def subject
        subject_method_name = self.class.subject_method_name
        raise(NoSubjectError, "You must define a .subject on #{self.class}") unless subject_method_name
        send(subject_method_name)
      end

      def to_hash
        hash_representation
      end

      def to_json
        json_representation
      end

      protected
      attr_reader :exposed_signal_values, :exposed_signal_value_subscriptions

      def after_first_retain
        self[:hash_representation] = create_hash_representation
        @exposed_signal_values = {}
        @exposed_signal_value_subscriptions = {}

        exposed_signals.each do |signal|
          relation = signal.value
          exposed_signal_values[signal] = relation.retain_with(self)
          exposed_signal_value_subscriptions[signal] = subscribe_to_relation(relation)
        end
      end

      def after_last_release
        self[:hash_representation] = nil
      end

      def subscribe_to_relation(relation)
        [
          relation.on_insert do |tuple|
            add_to_hash_representation(relation, tuple)
            attribute_mutated(:hash_representation)
          end,
          relation.on_delete do |tuple|
            remove_from_hash_representation(relation, tuple)
            attribute_mutated(:hash_representation)
          end,
          relation.on_tuple_update do |tuple, attribute, old_value, new_value|
            update_in_hash_representation(relation, tuple, attribute, new_value)
            attribute_mutated(:hash_representation)
          end
        ]
      end

      def subscribe_to_signal(signal)
        signal.on_change do |new_value|
          exposed_signal_values[signal].release_from(self)
          exposed_signal_value_subscriptions[signal].each do |subscription|
            subscription.destroy
          end

          exposed_signal_values[signal] = new_value.retain_with(self)
          exposed_signal_value_subscriptions[signal] = subscribe_to_relation(new_value)
        end
      end

      def create_hash_representation
        hash = {}
        exposed_objects.each do |object|
          case object
          when Relations::Relation
            object.tuples.each do |tuple|
              add_to_hash_representation(object, tuple, hash)
            end
          when Signals::DerivedSignal
            object.value.tuples.each do |tuple|
              add_to_hash_representation(object.value, tuple, hash)
            end
          end
        end
        hash
      end

      def add_to_hash_representation(relation, tuple, hash_representation=self.hash_representation)
        hash_representation[relation.tuple_class.basename] ||= {}
        hash_representation[relation.tuple_class.basename][tuple[:id]] = tuple.hash_representation.stringify_keys
      end

      def remove_from_hash_representation(relation, tuple)
        hash_representation[relation.tuple_class.basename].delete(tuple[:id])
      end

      def update_in_hash_representation(relation, tuple, attribute, new_value)
        hash_representation[relation.tuple_class.basename][tuple[:id]][attribute.name.to_s] = new_value
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
