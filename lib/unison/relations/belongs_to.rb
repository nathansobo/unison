module Unison
  module Relations
    class BelongsTo < SingletonRelation
      include CommonInferredRelationMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(Selection.new(target_class.set, target_class.set[:id].eq(owner.signal(foreign_key))))
        singleton
      end

      def foreign_key
        options[:foreign_key] || :"#{name}_id"
      end

      def create(attributes={})
        created_tuple = target_class.create(attributes)
        owner[foreign_key] = created_tuple[:id]
        created_tuple
      end
    end
  end
end