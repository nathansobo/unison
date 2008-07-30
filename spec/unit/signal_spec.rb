require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  module Tuple
    describe Signal do
      attr_reader :user, :signal
      before do
        @user = User.find(1)
        @signal = Signal.new(user, users_set[:name])
      end

      describe "#value" do
        it "returns the #attribute value from the #tuple" do
          user[:name].should_not be_nil
          signal.value.should == user[:name]
        end
      end

      describe "#trigger_on_update" do
        context "when passed a block" do
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

        context "when not passed a block" do
          it "raises an ArgumentError" do
            lambda do
              signal.on_update
            end.should raise_error(ArgumentError)
          end
        end
      end
    end
  end
end