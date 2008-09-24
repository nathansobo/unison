require File.expand_path("#{File.dirname(__FILE__)}/../../../unison_spec_helper")

module Unison
  module Adapters
    module Arel
      describe Engine do
        attr_reader :engine, :set
        before do
          @set = users_set
          @engine = Engine.new(set)
        end

        describe "#columns" do
          it "returns #set.primitive_attributes regardless of the passed in argument(s)" do
            engine.columns("users").should == set.primitive_attributes
            engine.columns("anything", "anything").should == set.primitive_attributes
          end
        end
      end
    end
  end
end