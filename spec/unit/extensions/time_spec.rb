require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Time do
  describe "#to_sql" do
    it "returns the database-formatted Time" do
      time = Time.utc(2008, 2, 2, 13, 22, 15)
      time.to_sql.should == "2008-02-02 13:22:15"
    end
  end
end