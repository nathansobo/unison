require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Integer do
  describe "#to_sql" do
    it "returns #to_s" do
      5.to_sql.should == "5"
    end
  end
end