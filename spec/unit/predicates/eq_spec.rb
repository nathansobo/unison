require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Predicates
    describe Eq do
      attr_reader :predicate

      before do
        @predicate = Eq.new(users_set[:name], "Nathan")
      end

      describe "#initialize" do
        context "when #operand_1 is a Signal" do
          attr_reader :user, :operand, :operand_subscription
          before do
            @user = User.find(1)
            @predicate = Eq.new(user.signal(:name), "Nathan")
            @operand = predicate.operand_1
            operand_subscriptions = predicate.send(:operand_subscriptions)
            operand_subscriptions.length.should == 1
            @operand_subscription = operand_subscriptions.first
          end

          it "#retains and #subscribes to #on_update on the Signal" do
            operand.should be_retained_by(predicate)

            operand.send(:update_subscriptions).should include(operand_subscription)
          end

          context "when #operand_1 is updated" do
            it "triggers the update Subscriptions" do
              on_update_called = false
              predicate.on_update do
                on_update_called = true
              end

              user[:name] = "Nathan2"
              on_update_called.should be_true
            end
          end
        end

        context "when #operand_2 is a Signal" do
          attr_reader :user, :operand, :operand_subscription
          before do
            @user = User.find(1)
            @predicate = Eq.new("Nathan", user.signal(:name))
            @operand = predicate.operand_2
            operand_subscriptions = predicate.send(:operand_subscriptions)
            operand_subscriptions.length.should == 1
            @operand_subscription = operand_subscriptions.first
          end

          it "#retains and #subscribes to #on_update on the Signal" do
            operand.should be_retained_by(predicate)

            operand.send(:update_subscriptions).should include(operand_subscription)
          end

          context "when #operand_2 is updated" do
            it "triggers the update Subscriptions" do
              on_update_called = false
              predicate.on_update do
                on_update_called = true
              end

              user[:name] = "Nathan2"
              on_update_called.should be_true
            end
          end
        end
      end
      
      describe "#eval" do
        it "returns true if one of the operands is an attribute and its value in the tuple =='s the other operand" do
          predicate.eval(User.new(:id => 1, :name => "Nathan")).should be_true
        end

        it "returns false if one of the operands is an attribute and its value in the tuple doesn't == the other operand" do
          predicate.eval(User.new(:id => 1, :name => "Corey")).should be_false
        end

        it "returns true if its operands are == when called on any tuple" do
          predicate = Eq.new(1, 1)
          predicate.eval(User.new(:id => 1, :name => "Nathan")).should be_true
        end

        context "when one of the operands is a Signal" do
          it "uses the value of the Signal in the predication" do
            user = User.new(:id => 1, :name => "Nathan")
            Eq.new(1, user.signal(:id)).eval(user).should be_true
            Eq.new(user.signal(:id), 1).eval(user).should be_true
          end
        end
      end

      describe "#==" do
        it "returns true for Eq predicates with == operands and false otherwise" do
          predicate.should == Eq.new(users_set[:name], "Nathan")
          predicate.should_not == Eq.new(users_set[:id], "Nathan")
          predicate.should_not == Eq.new(users_set[:name], "Corey")
          predicate.should_not == Object.new
        end
      end

      describe "#destroy" do
        context "when #operand_1 and #operand_2 are not Signals" do
          before do
            @predicate = Eq.new("Nathan", "Nathan")
          end
          
          it "does not raise an error" do
            predicate.send(:destroy)
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
            predicate.send(:destroy)
            operand.send(:update_subscriptions).should be_empty
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
            predicate.send(:destroy)
            operand.should_not be_retained_by(predicate)
            operand.send(:update_subscriptions).should be_empty
          end
        end
      end

      describe "#on_update" do
        it "returns a Subscription" do
          predicate.on_update {}.class.should == Subscription
        end
      end
    end
  end
end
