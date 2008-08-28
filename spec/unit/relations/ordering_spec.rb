require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Ordering do
      attr_reader :operand, :attribute, :ordering
      before do
        @operand = users_set
        @attribute = users_set[:name]
        @ordering = Ordering.new(operand, attribute)
      end

      describe "when not #retained?" do
        describe "#tuples" do
          it "returns the #operand's #tuples, ordered by the #attribute" do
            tuples_in_expected_order = operand.tuples.sort_by {|tuple| tuple[attribute]}
            tuples_in_expected_order.should_not == operand.tuples

            ordering.tuples.should == tuples_in_expected_order
          end
        end
      end
    end
  end
end
