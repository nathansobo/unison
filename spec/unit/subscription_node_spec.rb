require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe SubscriptionNode do
    attr_reader :node

    before do
      @node = SubscriptionNode.new
    end

    describe "#subscribe" do
      it "returns a Subscription" do
        node.subscribe {}.class.should == Subscription
      end

      it "creates a Subscription and adds it to its collection" do
        subscription = node.subscribe {}
        node.should == [subscription]
      end
    end

    describe "#call" do
      it "calls #call on all of its children" do
        subscription_1_args = []
        node.subscribe {|*args| subscription_1_args.push(args)}
        subscription_2_args = []
        node.subscribe {|*args| subscription_2_args.push(args)}

        node.call(1, 2, 3)
        subscription_1_args.should == [[1, 2, 3]]
        subscription_2_args.should == [[1, 2, 3]]
      end
    end
  end
end
