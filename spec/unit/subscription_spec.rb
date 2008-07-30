require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe Subscription do
    describe "#initialize" do
      context "when a block is passed in" do
        it "adds itself to its #event_node" do
          event_node = []
          subscription = Subscription.new(event_node) {}
          event_node.should == [subscription]
        end
      end

      context "when a block is not passed in" do
        it "raises an ArgumentError" do
          lambda do
            Subscription.new([])
          end.should raise_error(ArgumentError)
        end
      end
    end

    describe "#call" do
      it "invokes the passed in proc" do
        invocation_args = nil
        subscription = Subscription.new([]) do |*args|
          invocation_args = args
        end

        subscription.call(1, 2, 3)
        invocation_args.should == [1, 2, 3]
      end
    end

    describe "#destroy" do
      it "removes itself from its #event_node" do
        event_node = []
        subscription = Subscription.new(event_node) {}
        event_node.should == [subscription]
        subscription.destroy
        event_node.should == []
      end
    end
  end
end
