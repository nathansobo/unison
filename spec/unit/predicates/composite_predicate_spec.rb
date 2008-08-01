require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Predicates
    describe CompositePredicate do
      attr_reader :user, :predicate, :signal, :child_predicate_without_signal, :child_predicate_subscribed_signal

      before do
        @user = User.find(1)
        @signal = user.signal(:name)
        @child_predicate_without_signal = Eq.new(users_set[:id], 1)
        @child_predicate_subscribed_signal = Eq.new(signal, "Nathan")
        @predicate = And.new(child_predicate_without_signal, child_predicate_subscribed_signal)
      end

      describe "#initialize" do
        it "retains its #child_predicates" do
          child_predicate_without_signal.should be_retained_by(predicate)
          child_predicate_subscribed_signal.should be_retained_by(predicate)
        end

        context "when passed no arguments" do
          it "raises an ArgumentError" do
            lambda do
              And.new
            end.should raise_error(ArgumentError)
          end
        end

        context "when a child Predicate is updated" do
          it "triggers update Subscriptions" do
            on_update_called = false
            predicate.on_update do
              on_update_called = true
            end
            mock.proxy(signal).trigger_on_update("Nathan", "Bob")
            mock.proxy(child_predicate_subscribed_signal).trigger_on_update

            user.name = "Bob"
            on_update_called.should be_true
          end
        end
      end

      describe "#==" do
        context "when other And has the same #child_predicates" do
          it "returns true" do
            predicate.should == And.new(*predicate.child_predicates)
          end
        end

        context "when other And does not have the same #child_predicates" do
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

      describe "#destroy" do
        it "unsubscribes from and releases #child_predicates" do
          child_predicates = predicate.child_predicates.dup
          predicate.send(:destroy)

          child_predicate_without_signal.send(:update_subscription_node).should be_empty
          child_predicate_subscribed_signal.send(:update_subscription_node).should be_empty
          child_predicate_without_signal.should_not be_retained_by(predicate)
          child_predicate_subscribed_signal.should_not be_retained_by(predicate)
        end
      end
    end
  end
end
