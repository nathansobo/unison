require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

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

      describe "#on_update" do
        it "returns a Subscription" do
          predicate.on_update {}.class.should == Subscription
        end

        it "adds the new Subscription to #update_subscriptions" do
          predicate.send(:update_subscriptions).should be_empty
          subscription = predicate.on_update {}
          predicate.send(:update_subscriptions).should == [subscription]
        end
      end
    end
  end
end
