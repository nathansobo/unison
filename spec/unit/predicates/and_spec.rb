require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Predicates
    describe And do
      attr_reader :user, :predicate, :signal, :child_predicate_without_signal, :child_predicate_subscribed_signal

      before do
        @user = User.find(1)
        @signal = user.signal(:name)
        @child_predicate_without_signal = Eq.new(users_set[:id], 1)
        @child_predicate_subscribed_signal = Eq.new(signal, "Nathan")
        @predicate = And.new(child_predicate_without_signal, child_predicate_subscribed_signal)
      end

      describe "#eval" do
        context "when the passed in Tuple causes all of the child Predicates to #eval to true" do
          it "returns true" do
            user = User.find(1)
            user.id.should == 1
            user.name.should == "Nathan"
            predicate.eval(user).should be_true
          end
        end

        context "when the passed in Tuple causes one of the child Predicates to not #eval to true" do
          it "returns false" do
            user = User.find(2)
            user.name = "Nathan"
            predicate.eval(user).should be_false
          end
        end
      end
    end
  end
end
