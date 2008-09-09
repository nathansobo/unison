module Unison
  module Relations
    class HasOne < Selection
      include TupleRelationMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(target_relation, target_relation[foreign_key].eq(owner[:id]))
        singleton
      end
    end
  end
end