require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

describe Unison do
  attr_reader :predicate_1, :predicate_2
  before do
    predicate_1 = users_set[:id].eq("nathan")
    predicate_2 = users_set[:name].eq("Nathan")
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
end