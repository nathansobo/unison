require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe Retainable do
    def retainable
      users_set
    end
    
    def retainer
      @retainer ||= Object.new
    end

    def anonymous_retainable_object
      Class.new {include Retainable}.new
    end

    describe ".retains" do
      attr_reader :retainable, :child, :children
      before do
        @child = anonymous_retainable_object
        @children = [anonymous_retainable_object, anonymous_retainable_object]

        retainable_class = Class.new do
          include Retainable

          retains :child, :children
          attr_reader :child, :children

          def initialize(child, children)
            @child, @children = child, children
          end
        end
        @retainable = retainable_class.new(child, children)
      end

      it "causes the objects named by the passed-in names to be retained after the first call to #retained_by" do
        child.should_not be_retained_by(retainable)
        children.each do |child_in_children|
          child_in_children.should_not be_retained_by(retainable)
        end

        retainable.retained_by(retainer)

        child.should be_retained_by(retainable)
        children.each do |child_in_children|
          child_in_children.should be_retained_by(retainable)
        end
      end

      it "causes the objects named by the passed-in names to be released after the last call to #released_by" do
        retainable.retained_by(retainer)
        child.should be_retained_by(retainable)
        children.each do |child_in_children|
          child_in_children.should be_retained_by(retainable)
        end

        retainable.released_by(retainer)

        child.should_not be_retained_by(retainable)
        children.each do |child_in_children|
          child_in_children.should_not be_retained_by(retainable)
        end
      end
    end

    describe "#retained_by" do
      it "returns self" do
        retainable.retained_by(Object.new).should == retainable
      end

      it "retains its .names_of_children_to_retain only upon its first invocation" do
        retainable = users_set.where(users_set[:id].eq(1))
        retainable.operand.should_not be_retained_by(retainable)

        mock.proxy(retainable.operand).retained_by(retainable)
        retainable.retained_by(Object.new)
        retainable.operand.should be_retained_by(retainable)

        dont_allow(retainable.operand).retained_by(retainable)
        retainable.retained_by(Object.new)
      end

      it "invokes #after_first_retain only after first invocation" do
        retainable = Relations::Set.new(:test)
        mock.proxy(retainable).after_first_retain
        retainable.retained_by(Object.new)

        dont_allow(retainable).after_first_retain
        retainable.retained_by(Object.new)
      end

      context "when passing in a retainer for the first time" do
        it "increments #refcount by 1" do
          lambda do
            retainable.retained_by(Object.new)
          end.should change {retainable.refcount}.by(1)
        end

        it "causes #retained_by? to return true for the retainer" do
          retainer = Object.new
          retainable.should_not be_retained_by(retainer)
          retainable.retained_by(retainer)
          retainable.should be_retained_by(retainer)
        end
      end

      context "when passing in a retainer for the second time" do
        it "raises an ArgumentError" do
          retainer = Object.new
          retainable.retained_by(retainer)

          lambda do
            retainable.retained_by(retainer)
          end.should raise_error(ArgumentError)
        end
      end
    end

    describe "#released_by" do
      before do
        retainable.retained_by(retainer)
        retainable.should be_retained_by(retainer)
      end

      it "causes #retained_by(retainer) to return false" do
        retainable.released_by(retainer)
        retainable.should_not be_retained_by(retainer)
      end

      it "decrements #refcount by 1" do
        lambda do
          retainable.released_by(retainer)
        end.should change {retainable.refcount}.by(-1)
      end

      context "when #refcount becomes > 0" do
        it "does not call #after_last_release on itself" do
          retainable.retained_by(Object.new)
          retainable.refcount.should be > 1
          dont_allow(retainable).after_last_release
          retainable.released_by(retainer)
        end
      end

      context "when #refcount becomes 0" do
        def retainable
          @retainable ||= users_set.where(users_set[:id].eq(1))
        end
        
        before do
          retainable.refcount.should == 1
        end

        it "calls #after_last_release on itself" do
          mock.proxy(retainable).after_last_release
          retainable.released_by(retainer)
        end
      end
    end

    describe "#retained?" do
      def retainable
        @retainable ||= Relations::Set.new(:test)
      end

      context "when retainable has been retained" do
        before do
          retainable.retained_by(Object.new)
        end

        it "returns true" do
          retainable.should be_retained
        end
      end

      context "when retainable has not been retained" do
        it "returns false" do
          retainable.should_not be_retained
        end
      end
    end

    describe "#subscribed_to?" do
      context "when #subscriptions contains a Subscription that is in the passed in SubscriptionNode" do
        def retainable
          @retainable ||= users_set.where(User[:id].eq(1))
        end

        it "returns true" do
          publicize retainable, :subscriptions
          publicize users_set, :insert_subscription_node

          retainable.retained_by(retainer)
          retainable.subscriptions.should_not be_empty

          retainable.should be_subscribed_to(users_set.insert_subscription_node)
        end
      end
    end    
  end
end
