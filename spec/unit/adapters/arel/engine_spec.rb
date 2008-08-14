require File.expand_path("#{File.dirname(__FILE__)}/../../../spec_helper")

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
          it "returns #set.attributes.values regardless of the passed in argument(s)" do
            engine.columns("users").should == set.attributes.values
            engine.columns("anything", "anything").should == set.attributes.values
          end
        end
      end
    end
  end
end