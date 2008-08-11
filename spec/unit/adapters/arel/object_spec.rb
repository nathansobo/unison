require File.expand_path("#{File.dirname(__FILE__)}/../../../spec_helper")

describe Object do
  describe "#to_arel" do
    it "returns self" do
      object = Object.new
      object.to_arel.should == object
    end
  end
end
