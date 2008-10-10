require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe Unison do
    attr_reader :predicate_1, :predicate_2
    before do
      predicate_1 = users_set[:id].eq("nathan")
      predicate_2 = users_set[:name].eq("Nathan")
    end

    describe ".clear_all_sets" do
      it "delegates to Relations::Set.clear_all" do
        mock(Relations::Set).clear_all
        Unison.clear_all_sets
      end
    end

    describe ".and" do
      it "instantiates a Predicates::And with the passed-in arguments" do
        Unison.and(predicate_1, predicate_2).should == Unison::Predicates::And.new(predicate_1, predicate_2)
      end
    end

    describe ".or" do
      it "instantiates a Predicates::Or with the passed-in arguments" do
        Unison.or(predicate_1, predicate_2).should == Unison::Predicates::Or.new(predicate_1, predicate_2)
      end
    end

    describe ".models_module" do
      it "defaults to Object" do
        Unison.models_module.should == Object
      end
    end

    describe ".models_module=" do
      it "sets the value of .models_module to the given Module" do
        expected_module = Module.new
        Unison.models_module = expected_module
        Unison.models_module.should == expected_module
      end
    end
  end
end