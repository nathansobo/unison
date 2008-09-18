require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  module Tuple
    describe AttributeSignal do
      attr_reader :user, :attribute, :signal
      before do
        @user = User.find("nathan")
        @attribute = users_set[:name]
        @signal = user.signal(attribute)
      end

      describe "#==" do
        context "when other is an AttributeSignal" do
          context "when other.attribute == #attribute and other.tuple == #tuple" do
            it "returns true" do
              signal.should == user.signal(attribute)
            end
          end

          context "when other.attribute == #attribute and other.tuple != #tuple" do
            it "returns true" do
              user_2 = User.find("corey")
              user_2.should_not == user
              signal.should_not == user_2.signal(attribute)
            end
          end

          context "when other.attribute != #attribute and other.tuple == #tuple" do
            it "returns true" do
              attribute_2 = users_set[:id]
              attribute_2.should_not == attribute
              signal.should_not == user.signal(attribute_2)
            end
          end
        end

        context "when other is not an AttributeSignal" do
          it "returns false" do
            signal.should_not == Object.new
          end
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          signal.retain_with(retainer)
        end

        it "retains its Tuple" do
          user.should be_retained_by(signal)
        end

        describe "#value" do
          it "returns the #attribute value from the #tuple" do
            user[:name].should_not be_nil
            signal.value.should == user[:name]
          end
        end

        describe "#on_change" do
          context "when passed a block" do
            it "returns a Subscription" do
              signal.on_change(retainer) {}.class.should == Subscription
            end

            context "when the #attribute's value is updated on the Tuple" do
              it "invokes the block" do
                on_update_arguments = []
                signal.on_change(retainer) do |*args|
                  on_update_arguments.push(args)
                end

                old_name = user[:name]
                new_name = "Joe Bob"
                user[:name] = new_name
                on_update_arguments.should == [
                  [old_name, new_name]
                ]
              end
            end

            context "when another #attribute's value is updated on the Tuple" do
              it "does not invoke the block" do
                signal.on_change(retainer) do |*args|
                  raise "Do not call me"
                end

                user[:id] = 100
              end
            end
          end
        end
      end

      context "when not #retained?" do
        describe "#value" do
          it "returns the #attribute value from the #tuple" do
            user[:name].should_not be_nil
            signal.value.should == user[:name]
          end
        end

        describe "#on_change" do
          context "when passed a block" do
            it "raises an error" do
              lambda do
                signal.on_change {}
              end.should raise_error
            end
          end
        end
      end
    end
  end
end
