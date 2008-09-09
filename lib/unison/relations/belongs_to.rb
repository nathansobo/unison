module Unison
  module Relations
    class BelongsTo < Selection
      include TupleRelationMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(target_relation, target_relation[:id].eq(owner[foreign_key]))
        singleton
      end

      def foreign_key
        options[:foreign_key] || :"#{name}_id"
      end
    end
  end
end