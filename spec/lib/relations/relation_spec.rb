require "#{File.dirname(__FILE__)}/../../spec_helper"

describe Unison::Relations::Relation do
  include Relations
  describe "#where" do
    it "returns a Selection with self as its #operand and the given predicate as its #predicate" do
      selection = users_set.where(users_set[:id].eq(1))
      selection.should be_an_instance_of(Selection)
      selection.operand.should == users_set
      selection.predicate.should == users_set[:id].eq(1)
    end
  end

  describe "#first" do
    it "returns the first tuple from #read" do
      users_set.first.should == users_set.read.first
    end
  end
end
