module Unison
  module Relations
    class HasMany < Selection
      include CommonInferredRelationMethods

      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        super(target_relation, target_relation[foreign_key].eq(owner[:id]))
      end

      def create(attributes={})
        target_class.create({foreign_key => owner.id}.merge(attributes))
      end
    end
  end
end