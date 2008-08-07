require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe TrueClass do
  describe "#to_sql" do
    it "returns true" do
      true.to_sql.should == "true"
    end
  end
end