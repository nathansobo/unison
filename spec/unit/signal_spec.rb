require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  module Tuple
    describe Signal do
      attr_reader :user, :attribute, :signal
      before do
        @user = User.find(1)
        @attribute = users_set[:name]
        @signal = user.signal(attribute)
      end

      describe "#to_arel" do
        it "delegates to #value.to_arel" do
          signal.to_arel.should == user[:name].to_arel
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

        describe "#on_update" do
          context "when passed a block" do
            it "returns a Subscription" do
              signal.on_update(retainer) {}.class.should == Subscription
            end

            context "when the #attribute's value is updated on the Tuple" do
              it "invokes the block" do
                on_update_arguments = []
                signal.on_update(retainer) do |*args|
                  on_update_arguments.push(args)
                end

                old_name = user[:name]
                new_name = "Joe Bob"
                user[:name] = new_name
                on_update_arguments.should == [
                  [user, old_name, new_name]
                ]
              end
            end

            context "when another #attribute's value is updated on the Tuple" do
              it "does not invoke the block" do
                signal.on_update(retainer) do |*args|
                  raise "Do not call me"
                end

                user[:id] = 100
              end
            end
          end
        end
      end
    end
  end
end
