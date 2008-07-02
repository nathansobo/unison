require "#{File.dirname(__FILE__)}/../../spec_helper"

module Unison
  module Relations
    describe Set do
      attr_reader :set
      before do
        @set = Set.new(:users)
      end

      describe "#initialize" do
        it "sets the name of the set" do
          set.name.should == :users
        end
      end

      describe "#attribute" do
        it "adds an Attribute to the Set by the given name" do
          set.attribute(:name)
          set.attributes.should == [Attribute.new(set, :name)]
        end
      end
    end
  end
end