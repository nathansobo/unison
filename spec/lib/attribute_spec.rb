require "#{File.dirname(__FILE__)}/../spec_helper"

module Unison
  describe Attribute do
    attr_reader :relation, :attribute
    before do
      @relation = Set.new(:user)
      @attribute = Attribute.new(relation, :name)
    end

    describe "#initialize" do
      it "sets the #relation and #name" do
        attribute.relation.should == relation
        attribute.name.should == :name
      end
    end

    describe "#==" do
      it "returns true for Attributes of the same relation and name and false otherwise" do
        attribute.should == Attribute.new(relation, :name)
        attribute.should_not == Attribute.new(Set.new(:foo), :name)
        attribute.should_not == Attribute.new(relation, :foo)
        attribute.should_not == Object.new
      end
    end
  end
end