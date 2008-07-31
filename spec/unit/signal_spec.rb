require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  module Tuple
    describe Signal do
      attr_reader :user, :signal
      before do
        @user = User.find(1)
        @signal = user.signal(users_set[:name])
      end

      describe "#initialize" do
        it "retains its Tuple" do
          user.should be_retained_by(signal)
        end
      end

      describe "#value" do
        it "returns the #attribute value from the #tuple" do
          user[:name].should_not be_nil
          signal.value.should == user[:name]
        end
      end

      describe "#destroy" do
        it "releases its Tuple" do
          signal.retain(Object.new)
          user.should be_retained_by(signal)
          signal.send(:destroy)
          user.should_not be_retained_by(signal)
        end

        context "when the Signal is registered in Tuple#signals[#attribute]" do
          it "removes itself from its Tuple#signals hash" do
            user.send(:signals)[users_set[:name]].should == signal
            signal.send(:destroy)
            user.send(:signals)[users_set[:name]].should be_nil
          end
        end

        context "when Signal is not registered in Tuple#signals[#attribute]" do
          it "removes itself from its Tuple#signals hash" do
            signal.send(:destroy)
            lambda do
              signal.send(:destroy)
            end.should raise_error
          end
        end
      end

      describe "#on_update" do
        it "returns a Subscription" do
          signal.on_update {}.class.should == Subscription
        end
      end

      describe "#trigger_on_update" do
        it "invokes all #on_update subscriptions" do
          on_update_arguments = nil
          signal.on_update do |tuple, old_value, new_value|
            on_update_arguments = [tuple, old_value, new_value]
          end

          old_name = user[:name]
          new_name = "Wilhelm"
          signal.trigger_on_update(old_name, new_name)
          on_update_arguments.should == [user, old_name, new_name]
        end
      end
    end
  end
end
