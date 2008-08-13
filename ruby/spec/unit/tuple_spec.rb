require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe Tuple do
    attr_reader :tuple_class, :tuple

    describe ".[]" do
      it "delegates to .relation" do
        mock.proxy(User.set)[:name]
        User[:name]
      end
    end
    
    describe ".where" do
      it "delegates to .relation" do
        predicate = User[:name].eq("Nathan")
        mock.proxy(User.set).where(User[:name].eq("Nathan"))
        User.where(User[:name].eq("Nathan"))
      end
    end

    describe ".find" do
      it "delegates to #find on the #relation" do
        User.find(1).should == User.set.find(1)
      end
    end

    describe ".basename" do
      it "returns the last segment of name" do
        tuple_class = Class.new(PrimitiveTuple::Base)
        stub(tuple_class).name {"Foo::Bar::Baz"}
        tuple_class.basename.should == "Baz"
      end
    end

    describe "#persisted" do
      it "if new? is true, composed_sets it to false" do
        user = User.find(1)
        user.should be_new
        user.persisted
        user.should_not be_new
        user.persisted
        user.should_not be_new
      end
    end
  end
end
