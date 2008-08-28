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

      describe "when #retained?" do
        before do
          ordering.retain(Object.new)
        end

        describe "when a Tuple is inserted into the #operand" do
          it "the Tuple is inserted into #tuples in a location consistent with the ordering" do
            operand.insert(User.new(:name => "Marcel", :hobby => "Dog Walking"))
            expected_tuples = operand.tuples.sort_by {|tuple| tuple[attribute]}
            expected_tuples.should_not == operand.tuples
            ordering.tuples.should == expected_tuples
          end
        end

        describe "when a Tuple is deleted from the #operand" do
          it "the Tuple is deleted from #tuples" do
            user_to_delete = operand.first
            ordering.tuples.should include(user_to_delete)
            operand.delete(user_to_delete)
            ordering.tuples.should_not include(user_to_delete)
          end
        end
      end


      describe "when not #retained?" do
        describe "#retain" do
          it "retains and subscribes to its #operand" do
            ordering.operand_subscriptions.should be_empty
            operand.should_not be_retained_by(ordering)

            ordering.retain(Object.new)
            ordering.operand_subscriptions.should_not be_empty
            operand.should be_retained_by(ordering)
          end

#          it "retains the Tuples inserted by initial_read" do
#            selection.retain(Object.new)
#            selection.should_not be_empty
#            selection.each do |tuple|
#              tuple.should be_retained_by(selection)
#            end
#          end
        end

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
