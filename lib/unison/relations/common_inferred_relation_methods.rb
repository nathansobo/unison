module Unison
  module Relations
    module CommonInferredRelationMethods
      protected
      attr_reader :owner, :name, :options
      def target_relation
        target_class.set
      end

      def target_class
        @target_class ||= Unison.models_module.const_get(class_name.to_s)
      end

      def foreign_key
        options[:foreign_key] || owner_class.set.default_foreign_key_name
      end

      def owner_class
        owner.class
      end

      def class_name
        options[:class_name] || name.to_s.classify
      end
    end
  end
end