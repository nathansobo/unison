require "#{File.dirname(__FILE__)}/../spec_helper"

describe Unison::Attribute do
  attr_reader :relation, :attribute
  before do
    @relation = Relations::Set.new(:user)
    @attribute = Attribute.new(relation, :name)
  end

  describe "#initialize" do
    it "Relations::Sets the #relation and #name" do
      attribute.relation.should == relation
      attribute.name.should == :name
    end
  end

  describe "#==" do
    it "returns true for Attributes of the same relation and name and false otherwise" do
      attribute.should == Attribute.new(relation, :name)
      attribute.should_not == Attribute.new(Relations::Set.new(:foo), :name)
      attribute.should_not == Attribute.new(relation, :foo)
      attribute.should_not == Object.new
    end
  end

  describe "predicate constructors" do
    describe "eq" do
      it "returns an instance of Predicates::Eq with the attribute and the argument as its operands" do
        predicate = attribute.eq(1)
        predicate.should be_an_instance_of(Predicates::Eq)
        predicate.operand_1.should == attribute
        predicate.operand_2.should == 1
      end
    end
  end
end