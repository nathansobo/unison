require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Predicates
    describe And do
      attr_reader :predicate

      before do
        @predicate = And.new(Eq.new(users_set[:id], 1), Eq.new(users_set[:name], "Nathan"))
      end

      describe "#initialize" do
        context "when passed no arguments" do
          it "raises an ArgumentError" do
            lambda do
              And.new
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#eval" do
        context "when the passed in Tuple all of the child Predicates to #eval to true" do
          it "returns true" do
            user = User.find(1)
            user.id.should == 1
            user.name.should == "Nathan"
            predicate.eval(user).should be_true
          end
        end

        context "when one of the child Predicates fail" do
          it "returns false" do
            user = User.find(2)
            user.name = "Nathan"
            predicate.eval(user).should be_false
          end
        end
      end

      describe "#==" do
        context "when other And has the same of #child_predicates" do
          it "returns true" do
            predicate.should == And.new(Eq.new(users_set[:id], 1), Eq.new(users_set[:name], "Nathan"))
          end
        end

        context "when other And does not have the #child_predicates" do
          it "returns false" do
            predicate.should_not == And.new(Eq.new(users_set[:id], 1))
          end
        end
        
        context "when other is not an And" do
          it "returns false" do
            predicate.should_not == Eq.new(users_set[:name], "Nathan")
          end
        end
      end
    end
  end
end
