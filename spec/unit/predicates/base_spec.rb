require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Predicates
    describe Base do
      attr_reader :predicate

      before do
        @predicate = Base.new
      end
      
      describe "#eval" do
        it "raises a NotImplementedError" do
          lambda do
            predicate.eval(Object.new)
          end.should raise_error(NotImplementedError)
        end
      end

      describe "#==" do
        it "returns true when other == self" do
          predicate.should == predicate
          predicate.should_not == Base.new
        end
      end

      describe "#on_change" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          predicate.retain_with(retainer)
        end

        after do
          predicate.release_from(retainer)
        end

        it "returns a Subscription" do
          predicate.on_change(retainer) {}.class.should == Subscription
        end

        it "adds the new Subscription to #update_subscription_node" do
          predicate.send(:update_subscription_node).should be_empty
          subscription = predicate.on_change(retainer) {}
          predicate.send(:update_subscription_node).should == [subscription]
        end
      end
    end
  end
end
