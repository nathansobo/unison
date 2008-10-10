require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Predicates
    describe CompositePredicate do
      attr_reader :user, :predicate, :signal, :child_predicate_without_signal, :child_predicate_with_signal

      before do
        @user = User.find("nathan")
        @signal = user.signal(:name)
        @child_predicate_without_signal = EqualTo.new(users_set[:id], 1)
        @child_predicate_with_signal = EqualTo.new(signal, "Nathan")
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

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          predicate.retain_with(retainer)
        end

        after do
          predicate.release_from(retainer)
        end

        describe "#==" do
          context "when other And has the same #operands" do
            it "returns true" do
              predicate.should == And.new(*predicate.operands)
            end
          end

          context "when other And does not have the same #operands" do
            it "returns false" do
              predicate.should_not == And.new(EqualTo.new(users_set[:id], 1))
            end
          end

          context "when other is not an And" do
            it "returns false" do
              predicate.should_not == EqualTo.new(users_set[:name], "Nathan")
            end
          end
        end

        describe "#on_change" do
          context "when a child Predicate is updated" do
            it "triggers update Subscriptions" do
              on_update_called = false
              predicate.on_change(retainer) do
                on_update_called = true
              end

              user.name = "Bob"
              on_update_called.should be_true
            end
          end
        end
      end
    end
  end
end
