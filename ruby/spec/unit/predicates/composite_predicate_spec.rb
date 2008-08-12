require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Predicates
    describe CompositePredicate do
      attr_reader :user, :predicate, :signal, :child_predicate_without_signal, :child_predicate_with_signal

      before do
        @user = User.find(1)
        @signal = user.signal(:name)
        @child_predicate_without_signal = Eq.new(users_set[:id], 1)
        @child_predicate_with_signal = Eq.new(signal, "Nathan")
        @predicate = And.new(child_predicate_without_signal, child_predicate_with_signal)
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

      context "after #retain is called" do
        before do
          predicate.retain(Object.new)
        end

        describe "#==" do
          context "when other And has the same #operands" do
            it "returns true" do
              predicate.should == And.new(*predicate.operands)
            end
          end

          context "when other And does not have the same #operands" do
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

        describe "#on_update" do
          context "when a child Predicate is updated" do
            it "triggers update Subscriptions" do
              on_update_called = false
              predicate.on_update do
                on_update_called = true
              end

              user.name = "Bob"
              on_update_called.should be_true
            end
          end
        end

        describe "#after_last_release" do
          it "unsubscribes from and releases #operands" do
            operands = predicate.operands.dup
            predicate.send(:after_last_release)

            child_predicate_without_signal.send(:update_subscription_node).should be_empty
            child_predicate_with_signal.send(:update_subscription_node).should be_empty
            child_predicate_without_signal.should_not be_retained_by(predicate)
            child_predicate_with_signal.should_not be_retained_by(predicate)
          end
        end
      end

      context "before #retain is called" do
        describe "#retain" do
          it "retains its #operands" do
            child_predicate_without_signal.should_not be_retained_by(predicate)
            child_predicate_with_signal.should_not be_retained_by(predicate)
            predicate.send(:child_predicate_subscriptions).should be_empty

            predicate.retain(Object.new)
            child_predicate_without_signal.should be_retained_by(predicate)
            child_predicate_with_signal.should be_retained_by(predicate)
            predicate.send(:child_predicate_subscriptions).should_not be_empty
          end
        end
      end
    end
  end
end
