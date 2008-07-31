require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe Tuple do
    attr_reader :tuple_class, :tuple

    describe ".[]" do
      it "delegates to .relation" do
        mock.proxy(User.relation)[:name]
        User[:name]
      end
    end

    describe ".where" do
      it "delegates to .relation" do
        predicate = User[:name].eq("Nathan")
        mock.proxy(User.relation).where(User[:name].eq("Nathan"))
        User.where(User[:name].eq("Nathan"))
      end
    end

    describe ".find" do
      it "when passed an integer, returns the first Tuple whose :id =='s it" do
        user = User.find(1)
        user.should be_an_instance_of(User)
        user[users_set[:id]].should == 1
      end
    end

    describe ".basename" do
      it "returns the last segment of name" do
        tuple_class = Class.new(PrimitiveTuple::Base)
        stub(tuple_class).name {"Foo::Bar::Baz"}
        tuple_class.basename.should == "Baz"
      end
    end
  end
end
