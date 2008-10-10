module Unison
  module Relations
    class HasOne < SingletonRelation
      include CommonInferredRelationMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(Selection.new(target_relation, target_relation[foreign_key].eq(owner[:id])))
        singleton
      end
    end
  end
end