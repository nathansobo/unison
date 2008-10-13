require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Tuples
    describe Tuple do
      attr_reader :tuple_class, :tuple

      describe ".[]" do
        it "delegates to .relation" do
          mock.proxy(User.set)[:name]
          User[:name]
        end
      end

      describe ".basename" do
        it "returns the last segment of name" do
          tuple_class = Class.new(PrimitiveTuple)
          stub(tuple_class).name {"Foo::Bar::Baz"}
          tuple_class.basename.should == "Baz"
        end
      end

      describe "#pushed" do
        it "if new? is true, sets it to false" do
          user = User.find("nathan")
          user.should be_new
          user.pushed
          user.should_not be_new
          user.pushed
          user.should_not be_new
        end
      end
    end    
  end
end
