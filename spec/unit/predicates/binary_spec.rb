require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Predicates
    describe Eq do
      attr_reader :predicate

      context "when #retained?" do
        attr_reader :retainer
        before do
          @predicate = Eq.new(users_set[:name], "Nathan")
          @retainer = Object.new
          predicate.retain_with(retainer)
        end

        describe "#==" do
          it "returns true for predicates of the same class with == operands and false otherwise" do
            predicate.class.should == Eq
            predicate.should == Eq.new(users_set[:name], "Nathan")
            predicate.should_not == Eq.new(users_set[:id], "Nathan")
            predicate.should_not == Eq.new(users_set[:name], "Corey")
            predicate.should_not == Object.new
          end
        end

        describe "#after_last_release" do
          context "when #operand_1 and #operand_2 are not Signals" do
            before do
              @predicate = Eq.new("Nathan", "Nathan")
            end

            it "does not raise an error" do
              predicate.send(:after_last_release)
            end
          end

          context "when #operand_1 is a Signal" do
            attr_reader :user, :operand
            before do
              @user = User.find(1)
              @predicate = Eq.new(user.signal(:name), "Nathan")
              @operand = predicate.operand_1
            end

            it "unsubscribes from and releases #operand_1" do
              predicate.send(:after_last_release)
              operand.send(:update_subscription_node).should be_empty
              operand.should_not be_retained_by(predicate)
            end
          end

          context "when #operand_2 is a Signal" do
            attr_reader :user, :operand
            before do
              @user = User.find(1)
              @predicate = Eq.new("Nathan", user.signal(:name))
              @operand = predicate.operand_2
            end

            it "unsubscribes from and releases #operand_1" do
              predicate.send(:after_last_release)
              operand.should_not be_retained_by(predicate)
              operand.send(:update_subscription_node).should be_empty
            end
          end
        end

        describe "#on_update" do
          it "returns a Subscription" do
            predicate.on_update(retainer) {}.class.should == Subscription
          end

          context "when #operand_1 is a Signal" do
            attr_reader :user, :operand, :operand_subscription
            before do
              @user = User.find(1)
              @predicate = Eq.new(user.signal(:name), "Nathan").retain_with(Object.new)
              predicate.retain_with(retainer)
              publicize predicate, :subscriptions
              @operand = predicate.operand_1
              subscriptions = predicate.subscriptions
              subscriptions.length.should == 1
              @operand_subscription = subscriptions.first
            end

            context "when #operand_1 is updated" do
              it "triggers the update Subscriptions" do
                on_update_called = false
                predicate.on_update(retainer) do
                  on_update_called = true
                end

                user[:name] = "Nathan2"
                on_update_called.should be_true
              end
            end
          end

          context "when #operand_2 is a Signal" do
            attr_reader :user, :operand
            before do
              @user = User.find(1)
              @predicate = Eq.new("Nathan", user.signal(:name)).retain_with(Object.new)
              predicate.retain_with(retainer)
              @operand = predicate.operand_2
              subscriptions = predicate.send(:subscriptions)
            end

            context "when #operand_2 is updated" do
              it "triggers the update Subscriptions" do
                on_update_called = false
                predicate.on_update(retainer) do
                  on_update_called = true
                end

                user[:name] = "Nathan2"
                on_update_called.should be_true
              end
            end
          end
        end
      end

      context "when not #retained?" do
        describe "#after_first_retain" do
          context "when #operand_1 is a Signal" do
            attr_reader :user, :operand
            before do
              @user = User.find(1)
              @predicate = Eq.new(user.signal(:name), "Nathan")
              @operand = predicate.operand_1
            end

            it "#retains and #subscribes to #on_update on the Signal" do
              mock.proxy(predicate).after_first_retain
              operand.should_not be_retained_by(predicate)
              predicate.send(:subscriptions).should be_empty

              predicate.retain_with(Object.new)
              operand.should be_retained_by(predicate)
              predicate.send(:subscriptions).should_not be_empty
            end
          end

          context "when #operand_2 is a Signal" do
            attr_reader :user, :operand
            before do
              @user = User.find(1)
              @predicate = Eq.new("Nathan", user.signal(:name))
              @operand = predicate.operand_2
            end

            it "#retains and #subscribes to #on_update on the Signal" do
              mock.proxy(predicate).after_first_retain
              operand.should_not be_retained_by(predicate)
              predicate.send(:subscriptions).should be_empty

              predicate.retain_with(Object.new)
              operand.should be_retained_by(predicate)
              predicate.send(:subscriptions).should_not be_empty
            end
          end
        end
      end
    end
  end
end