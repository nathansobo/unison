require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe String do
  describe "#to_sql" do
    it "returns 'string'" do
      "Hello".to_sql.should == "'Hello'"
    end

    it "escapes quotes" do
      "Hi 'Bob'".to_sql.should == "'Hi ''Bob'''"
    end

    it "escapes backslashes" do
      'Hey \you'.to_sql.should == "'Hey \\\\you'"
    end
  end
end