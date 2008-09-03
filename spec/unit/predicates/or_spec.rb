require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Predicates
    describe Or do
      attr_reader :predicate, :operand_1, :operand_2

      before do
        @operand_1 = Eq.new(users_set[:id], 3)
        @operand_2 = Eq.new(users_set[:name], "Nathan")
        @predicate = Or.new(operand_1, operand_2)
      end

      describe "#eval" do
        context "when the passed in Tuple causes one of the child Predicates to #eval to true" do
          it "returns true" do
            user = User.find(1)
            user.id.should_not == 3
            user.name.should == "Nathan"
            predicate.eval(user).should be_true
          end
        end

        context "when the passed in Tuple causes none of the child Predicates to #eval to true" do
          it "returns false" do
            user = User.find(2)
            user.name.should_not == 3
            user.name.should_not == "Nathan"
            predicate.eval(user).should be_false
          end
        end
      end

      describe "#to_arel" do
        it "return to_arel value of each operand joined by and" do
          predicate.to_arel.should == operand_1.to_arel.or(operand_2.to_arel)
        end
      end
    end
  end
end
