module Unison
  module Relations
    class BelongsTo < SingletonRelation
      include TupleRelationMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(Selection.new(target_class.set, target_class.set[:id].eq(owner.signal(foreign_key))))
        singleton
      end

      def foreign_key
        options[:foreign_key] || :"#{name}_id"
      end
    end
  end
end