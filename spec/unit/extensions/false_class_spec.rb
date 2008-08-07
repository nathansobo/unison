require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe FalseClass do
  describe "#to_sql" do
    it "returns false" do
      false.to_sql.should == "false"
    end
  end
end