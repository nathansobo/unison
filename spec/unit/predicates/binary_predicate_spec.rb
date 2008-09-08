require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Predicates
    describe BinaryPredicate do
      attr_reader :predicate, :operand_1, :operand_2
      before do
        @predicate = EqualTo.new(operand_1, operand_2)
      end

      def operand_1
        users_set[:name]
      end

      def operand_2
        "Nathan"
      end

      describe "#==" do
        it "returns true for predicates of the same class with == operands and false otherwise" do
          predicate.class.should == EqualTo
          predicate.should == EqualTo.new(users_set[:name], "Nathan")
          predicate.should_not == EqualTo.new(users_set[:id], "Nathan")
          predicate.should_not == EqualTo.new(users_set[:name], "Corey")
          predicate.should_not == Object.new
        end
      end      

      describe "#eval" do
        context "when one of the operands is a Signal" do
          it "uses the value of the Signal in the predication" do
            user = User.new(:id => 1, :name => "Nathan")
            EqualTo.new(1, user.signal(:id)).eval(user).should be_true
            EqualTo.new(user.signal(:id), 1).eval(user).should be_true
          end
        end
      end
      
      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          predicate.retain_with(retainer)
        end

        describe "#after_last_release" do
          context "when #operand_1 and #operand_2 are not Signals" do
            before do
              operand_1.should_not be_instance_of(Signal)
              operand_2.should_not be_instance_of(Signal)
            end

            it "does not raise an error" do
              predicate.send(:after_last_release)
            end
          end

          context "when #operand_1 is a Signal" do
            attr_reader :user

            before do
              publicize operand, :update_subscription_node              
            end

            def operand_1
              @user ||= User.find(1)
              @operand_1 ||= user.signal(:name)
            end
            alias_method :operand, :operand_1

            it "unsubscribes from and releases #operand_1" do
              operand.should be_retained_by(predicate)
              predicate.should be_subscribed_to(operand.update_subscription_node)

              mock.proxy(predicate).after_last_release
              predicate.release_from(retainer)
              
              predicate.should_not be_subscribed_to(operand.update_subscription_node)
              operand.should_not be_retained_by(predicate)
            end
          end

          context "when #operand_2 is a Signal" do
            attr_reader :user
            before do
              publicize operand, :update_subscription_node
            end

            def operand_2
              @user ||= User.find(1)
              @operand_2 ||= user.signal(:name)
            end
            alias_method :operand, :operand_2

            it "unsubscribes from and releases #operand_2" do
              operand.should be_retained_by(predicate)
              predicate.should be_subscribed_to(operand.update_subscription_node)

              mock.proxy(predicate).after_last_release
              predicate.release_from(retainer)

              predicate.should_not be_subscribed_to(operand.update_subscription_node)
              operand.should_not be_retained_by(predicate)
            end
          end
        end

        describe "#on_update" do
          it "returns a Subscription" do
            predicate.on_update(retainer) {}.class.should == Subscription
          end

          context "when #operand_1 is a Signal" do
            attr_reader :user

            def operand_1
              @user ||= User.find(1)
              user.signal(:name)
            end
            alias_method :operand, :operand_1

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
            attr_reader :user

            def operand_2
              @user ||= User.find(1)
              user.signal(:name)
            end
            alias_method :operand, :operand_2

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
            attr_reader :user

            before do
              publicize operand, :update_subscription_node              
            end

            def operand_1
              @user ||= User.find(1)
              @operand_1 ||= user.signal(:name)
            end
            alias_method :operand, :operand_1
            
            it "#retains and #subscribes to #on_update on the Signal" do
              mock.proxy(predicate).after_first_retain
              operand.should_not be_retained_by(predicate)
              predicate.should_not be_subscribed_to(operand.update_subscription_node)

              predicate.retain_with(Object.new)
              
              operand.should be_retained_by(predicate)
              predicate.should be_subscribed_to(operand.update_subscription_node)
            end
          end

          context "when #operand_2 is a Signal" do
            attr_reader :user, :operand
            before do
              @user = User.find(1)
              @predicate = EqualTo.new("Nathan", user.signal(:name))
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