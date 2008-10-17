module Unison
  module Relations
    class HasOne < SingletonRelation
      include CommonInferredRelationMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(Selection.new(target_relation, target_relation[foreign_key].eq(owner[:id])))
        singleton
      end

      def create(attributes={})
        target_class.create({foreign_key => owner.id}.merge(attributes))
      end
    end
  end
end