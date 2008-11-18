require File.expand_path("#{File.dirname(__FILE__)}/../../../unison_spec_helper")

describe Object do
  describe "#fetch_arel" do
    it "returns self" do
      object = Object.new
      object.fetch_arel.should == object
    end
  end
end
