require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe SubscriptionNode do
    attr_reader :owner, :retainer, :node

    before do
      @owner = users_set
      @retainer = Object.new
      @node = SubscriptionNode.new(owner)
    end
    
    context "when the #owner is retained by the subscriber" do
      before do
        owner.retain_with(retainer)
      end

      describe "#subscribe" do
        it "returns a Subscription" do
          node.subscribe(retainer) {}.class.should == Subscription
        end

        it "creates a Subscription and adds it to its collection" do
          subscription = node.subscribe(retainer) {}
          node.should == [subscription]
        end
      end

      describe "#call" do
        it "calls #call on all of its children" do
          subscription_1_args = []
          node.subscribe(retainer) {|*args| subscription_1_args.push(args)}
          subscription_2_args = []
          node.subscribe(retainer) {|*args| subscription_2_args.push(args)}

          node.call(1, 2, 3)
          subscription_1_args.should == [[1, 2, 3]]
          subscription_2_args.should == [[1, 2, 3]]
        end

        it "returns the passed in arguments" do
          node.call(1, 2, 3).should == [1, 2, 3]
        end
      end
    end

    context "when the #owner is not retained by the subscriber" do
      describe "#subscribe" do
        it "raises an ArgumentError" do
          lambda do
            node.subscribe(retainer) {}
          end.should raise_error(ArgumentError)
        end
      end
    end
  end
end
