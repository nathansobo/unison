require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Predicates
    describe Or do
      attr_reader :predicate

      before do
        @predicate = Or.new(Eq.new(users_set[:id], 3), Eq.new(users_set[:name], "Nathan"))
      end

      describe "#initialize" do
        context "when passed no arguments" do
          it "raises an ArgumentError" do
            lambda do
              Or.new
            end.should raise_error(ArgumentError)
          end
        end
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

      describe "#==" do
        context "when other Or has the same #child_predicates" do
          it "returns true" do
            predicate.should == Or.new(Eq.new(users_set[:id], 3), Eq.new(users_set[:name], "Nathan"))
          end
        end

        context "when other Or does not have the same #child_predicates" do
          it "returns false" do
            predicate.should_not == Or.new(Eq.new(users_set[:id], 1))
          end
        end

        context "when other is not an Or" do
          it "returns false" do
            predicate.should_not == Eq.new(users_set[:name], "Nathan")
          end
        end
      end
    end
  end
end
