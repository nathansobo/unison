require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe RelationDefinition do
    describe "#initialize_relation" do
      it "creates a Relation by instance evaling the definition block in the passed in instance" do
        relation = users_set
        passed_in_instance = nil
        definition_block = lambda do
          passed_in_instance = self
          relation
        end
        definition = RelationDefinition.new(:relation_name, definition_block, caller, false)

        instance = Object.new        
        definition.initialize_relation(instance).should == relation
        passed_in_instance.should == instance
      end

      it "sets an instance variable on the passed in instance to the created Relation" do
        relation = users_set
        definition_block = lambda {relation}
        definition = RelationDefinition.new(:relation_name, definition_block, caller, false)

        instance = Object.new
        definition.initialize_relation(instance).should == relation
        instance.instance_variable_get("@relation_name_relation").should == relation
      end

      context "is_singleton? is false" do
        it "returns the Relation created in the #definition" do
          relation = users_set
          definition_proc = lambda {relation}
          definition = RelationDefinition.new(:relation_name, definition_proc, caller, false)

          definition.initialize_relation(Object.new).should == relation
        end
      end

      context "is_singleton? is true" do
        it "returns a SingletonRelation whose #operand is the Relation created in the #definition" do
          relation = users_set
          definition_proc = lambda {relation}
          definition = RelationDefinition.new(:relation_name, definition_proc, caller, true)

          created_relation = definition.initialize_relation(Object.new)
          created_relation.class.should == Relations::SingletonRelation
          created_relation.operand.should == relation
        end
      end
    end
  end
end
