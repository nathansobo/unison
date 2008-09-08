require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe InstanceRelationDefinition do
    describe "#initialize_instance_relation" do
      it "creates a Relation by instance evaling the definition block in the passed in instance" do
        relation = users_set
        passed_in_instance = nil
        definition_block = lambda do
          passed_in_instance = self
          relation
        end
        definition = InstanceRelationDefinition.new(:relation_name, definition_block, caller, false)

        instance = Object.new        
        definition.initialize_instance_relation(instance).should == relation
        passed_in_instance.should == instance
      end

      it "sets an instance variable on the passed in instance to the created Relation" do
        relation = users_set
        definition_block = lambda {relation}
        definition = InstanceRelationDefinition.new(:relation_name, definition_block, caller, false)

        instance = Object.new
        definition.initialize_instance_relation(instance).should == relation
        instance.instance_variable_get("@relation_name_relation").should == relation
      end

      context "when not singleton" do
        it "sets #singleton? to false on the created Relation" do
          relation = users_set
          definition_block = lambda {relation}
          definition = InstanceRelationDefinition.new(:relation_name, definition_block, caller, false)

          relation.should_not be_singleton
          definition.initialize_instance_relation(Object.new).should_not be_singleton
        end
      end

      context "when singleton" do
        it "sets #singleton? to true on the created Relation" do
          relation = users_set
          definition_block = lambda {relation}
          definition = InstanceRelationDefinition.new(:relation_name, definition_block, caller, true)

          relation.should_not be_singleton
          definition.initialize_instance_relation(Object.new).should be_singleton
        end
      end
    end
  end
end
