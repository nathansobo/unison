require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Predicates
    describe Or do
      attr_reader :predicate

      before do
        @predicate = Or.new(Eq.new(users_set[:id], 3), Eq.new(users_set[:name], "Nathan"))
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

      describe "#to_sql" do
        it "return to_sql value of each operand joined by or" do
          predicate.to_sql.should == "((users.id = 3) or (users.name = 'Nathan'))"
        end
      end
    end
  end
end
