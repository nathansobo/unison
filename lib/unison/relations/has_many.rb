module Unison
  module Relations
    class HasMany < Selection
      module CommonInstanceMethods
        attr_reader :owner, :name, :options        
        def target_relation
          target_class.set
        end

        def target_class
          @target_class ||= class_name.to_s.constantize
        end

        def owner_class
          owner.class
        end

        def class_name
          options[:class_name] || name.to_s.classify
        end
      end
      include CommonInstanceMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(target_relation, target_relation[foreign_key].eq(owner[:id]))
      end

      def foreign_key
        options[:foreign_key] || owner_class.set.default_foreign_key_name
      end
    end
  end
end