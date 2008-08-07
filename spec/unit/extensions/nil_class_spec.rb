require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe NilClass do
  describe "#to_sql" do
    it "returns null" do
      nil.to_sql.should == "null"
    end
  end
end