require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Attributes
    describe SyntheticAttribute do
      attr_reader :set, :attribute, :definition, :tuple
      before do
        @set = users_set
        @definition = lambda {signal(:name).signal(:length)}
        @attribute = SyntheticAttribute.new(set, :name_length, &definition)
        set.attributes[attribute.name] = attribute
        @tuple = User.create(:id => "bob", :name => "Bobby")
      end

      describe "#initialize" do
        it "sets the #set, #name, and #definition" do
          attribute.set.should == set
          attribute.name.should == :name_length
          attribute.definition.should == definition
        end
      end

      describe "#==" do
        it "returns true for Attributes of the same #set, #name, and #definition and returns false otherwise" do
          attribute.should == SyntheticAttribute.new(set, :name_length, &definition)
          attribute.should_not == SyntheticAttribute.new(Relations::Set.new(:foo), :name_length)
          attribute.should_not == SyntheticAttribute.new(set, :foo)
          attribute.should_not == SyntheticAttribute.new(set, :name_length) {}
          attribute.should_not == Object.new
        end
      end

      describe "#field" do
        it "returns a Field instance with the passed-in #tuple and self set to #attribute" do
          field = attribute.field(tuple)
          field.class.should == Field
          field.tuple.should == tuple
          field.attribute.should == attribute
        end
      end
    end
  end
end

