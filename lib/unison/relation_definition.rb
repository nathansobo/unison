module Unison
  class RelationDefinition
    attr_reader :name, :definition, :definition_backtrace, :is_singleton
    def initialize(name, definition, definition_backtrace, is_singleton)
      @name, @definition, @definition_backtrace, @is_singleton = name, definition, definition_backtrace, is_singleton
    end

    def initialize_relation(tuple_instance)
      begin
        definition_relation = tuple_instance.instance_eval(&definition)
        relation = singleton?? definition_relation.singleton : definition_relation
        tuple_instance.instance_variable_set("@#{name}_relation", relation)
      rescue Exception => e
        e.message.concat("\nThe above error was caused by the relation definition at:\n\t#{definition_backtrace.join("\n\t\t")}\n\nThe actual exception backtrace is:\n")
        raise e
      end
    end

    protected
    alias_method :singleton?, :is_singleton
  end
end