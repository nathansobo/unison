module Unison
  module Relations
    class HasManyThrough < Projection
      include TupleRelationMethods
      
      attr_reader :foreign_key, :foreign_key_owner, :foreign_key_referrent
      def initialize(owner, name, options)
        @owner, @name, @options = owner, name, options
        infer_foreign_key
        join = through_relation.
          join(target_relation).
            on(foreign_key_owner[foreign_key].eq(foreign_key_referrent[:id]))
        super(join, target_relation)
      end

      def through_relation
        owner.send("#{options[:through]}_relation")
      end

      def infer_foreign_key
        if through_relation.has_attribute?(options[:foreign_key] || target_relation.default_foreign_key_name)
          @foreign_key = options[:foreign_key] || target_relation.default_foreign_key_name
          @foreign_key_owner = through_relation
          @foreign_key_referrent = target_relation
        elsif target_relation.has_attribute?(options[:foreign_key] || through_relation.set.default_foreign_key_name)
          @foreign_key = options[:foreign_key] || through_relation.set.default_foreign_key_name
          @foreign_key_owner = target_relation
          @foreign_key_referrent = through_relation
        else
          raise(ArgumentError, "Unable to construct a has_many\n#{target_relation.inspect}\nrelationship through\n#{through_relation.inspect}\nwith options #{options.inspect}")
        end
      end
    end
  end
end