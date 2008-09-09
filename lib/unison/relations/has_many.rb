module Unison
  module Relations
    class HasMany < Selection
      include TupleRelationMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(target_relation, target_relation[foreign_key].eq(owner[:id]))
      end
    end
  end
end